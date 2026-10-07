from datetime import date, timedelta
from fastapi.responses import StreamingResponse
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import text

from database import engine
from utils.auth import require_admin


from io import BytesIO

from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)



router = APIRouter(
    prefix="/admin/reports",
    tags=["Admin Reports"]
)


ALLOWED_REPORT_TABLES = [
    "USERS",
    "PRODUCTS",
    "PRODUCT_IMAGES",
    "UNSUPPORTED_PRODUCTS",
]


REPORT_DATE_COLUMNS = {
    "USERS": "CREATED_AT",
    "PRODUCTS": "CREATED_AT",
    "PRODUCT_IMAGES": "CREATED_AT",
    "UNSUPPORTED_PRODUCTS": "CREATED_AT",
}
@router.get("/tables")
def get_report_tables(
    admin=Depends(require_admin)
):
    return {
        "tables": ALLOWED_REPORT_TABLES
    }

@router.get("")
def generate_report(
    table_name: str,
    period: str,
    start_date: date | None = None,
    end_date: date | None = None,
    admin=Depends(require_admin)
):
    admin_user_id = admin.get("user_id")

    if not admin_user_id:
        raise HTTPException(
            status_code=401,
            detail="Admin identity not found"
        )

    try:
        with engine.connect() as connection:
            admin_user = connection.execute(
                text("""
                    SELECT
                        U_ID,
                        U_NAME
                    FROM USERS
                    WHERE U_ID = :user_id
                      AND ROLE = 'ADMIN'
                    LIMIT 1
                """),
                {
                    "user_id": admin_user_id
                }
            ).fetchone()

        if not admin_user:
            raise HTTPException(
                status_code=401,
                detail="Admin user not found"
            )

        generated_by = {
            "user_id": admin_user.U_ID,
            "name": admin_user.U_NAME
        }

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    table_name = table_name.upper().strip()
    period = period.lower().strip()

    if table_name not in ALLOWED_REPORT_TABLES:
        raise HTTPException(
            status_code=400,
            detail="Invalid report table"
        )

    date_column = REPORT_DATE_COLUMNS.get(table_name)

    if not date_column:
        raise HTTPException(
            status_code=400,
            detail="Report date column not configured"
        )

    today = date.today()

    if period == "weekly":

        report_start = today - timedelta(
            days=today.weekday()
        )

        report_end = report_start + timedelta(days=7)

    elif period == "monthly":

        report_start = today.replace(day=1)

        if report_start.month == 12:
            report_end = date(
                report_start.year + 1,
                1,
                1
            )
        else:
            report_end = date(
                report_start.year,
                report_start.month + 1,
                1
            )

    elif period == "yearly":

        report_start = date(
            today.year,
            1,
            1
        )

        report_end = date(
            today.year + 1,
            1,
            1
        )

    elif period == "custom":

        if not start_date or not end_date:
            raise HTTPException(
                status_code=400,
                detail=(
                    "start_date and end_date "
                    "are required for custom report"
                )
            )

        if start_date > end_date:
            raise HTTPException(
                status_code=400,
                detail="start_date cannot be after end_date"
            )

        report_start = start_date
        report_end = end_date + timedelta(days=1)

    else:

        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid period. "
                "Use weekly, monthly, yearly, or custom"
            )
        )

    if table_name == "USERS":

        select_columns = """
            U_ID,
            U_NAME,
            EMAIL,
            ROLE,
            CREATED_AT
        """

    else:
        select_columns = "*"

    query = text(
        f"""
        SELECT {select_columns}
        FROM {table_name}
        WHERE {date_column} >= :report_start
          AND {date_column} < :report_end
        ORDER BY {date_column} DESC
        """
    )

    try:

        with engine.begin() as connection:

            result = connection.execute(
                query,
                {
                    "report_start": report_start,
                    "report_end": report_end
                }
            )

            rows = result.mappings().all()

        return {
            "table_name": table_name,
            "period": period,
            "start_date": report_start,
            "end_date": report_end - timedelta(days=1),
            "count": len(rows),
            "generated_by": generated_by,
            "rows": [
                dict(row)
                for row in rows
            ]
        }

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

@router.get("/pdf")
def download_report_pdf(
    table_name: str,
    period: str,
    start_date: date | None = None,
    end_date: date | None = None,
    admin=Depends(require_admin)
):
    admin_user_id = admin.get("user_id")

    if not admin_user_id:
        raise HTTPException(
            status_code=401,
            detail="Admin identity not found"
        )

    try:
        with engine.connect() as connection:
            admin_user = connection.execute(
                text("""
                    SELECT
                        U_ID,
                        U_NAME
                    FROM USERS
                    WHERE U_ID = :user_id
                      AND ROLE = 'ADMIN'
                    LIMIT 1
                """),
                {
                    "user_id": admin_user_id
                }
            ).fetchone()

        if not admin_user:
            raise HTTPException(
                status_code=401,
                detail="Admin user not found"
            )

        generated_by_name = admin_user.U_NAME

    except HTTPException:
        raise

    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=str(e)
        )

    
    table_name = table_name.upper().strip()
    period = period.lower().strip()

    if table_name not in ALLOWED_REPORT_TABLES:
        raise HTTPException(
            status_code=400,
            detail="Invalid report table"
        )

    date_column = REPORT_DATE_COLUMNS.get(table_name)

    if not date_column:
        raise HTTPException(
            status_code=400,
            detail="Report date column not configured"
        )

    today = date.today()

    if period == "weekly":

        report_start = today - timedelta(
            days=today.weekday()
        )

        report_end = report_start + timedelta(days=7)

    elif period == "monthly":

        report_start = today.replace(day=1)

        if report_start.month == 12:
            report_end = date(
                report_start.year + 1,
                1,
                1
            )
        else:
            report_end = date(
                report_start.year,
                report_start.month + 1,
                1
            )

    elif period == "yearly":

        report_start = date(
            today.year,
            1,
            1
        )

        report_end = date(
            today.year + 1,
            1,
            1
        )

    elif period == "custom":

        if not start_date or not end_date:
            raise HTTPException(
                status_code=400,
                detail=(
                    "start_date and end_date "
                    "are required for custom report"
                )
            )

        if start_date > end_date:
            raise HTTPException(
                status_code=400,
                detail="start_date cannot be after end_date"
            )

        report_start = start_date
        report_end = end_date + timedelta(days=1)

    else:

        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid period. "
                "Use weekly, monthly, yearly, or custom"
            )
        )

    if table_name == "USERS":

        select_columns = """
            U_ID,
            U_NAME,
            EMAIL,
            ROLE,
            CREATED_AT
        """

    else:
        select_columns = "*"

    query = text(
        f"""
        SELECT {select_columns}
        FROM {table_name}
        WHERE {date_column} >= :report_start
          AND {date_column} < :report_end
        ORDER BY {date_column} DESC
        """
    )

    try:

        with engine.begin() as connection:

            result = connection.execute(
                query,
                {
                    "report_start": report_start,
                    "report_end": report_end
                }
            )

            rows = result.mappings().all()

        # -------------------------
        # CREATE PDF
        # -------------------------

        pdf_buffer = BytesIO()

        document = SimpleDocTemplate(
            pdf_buffer,
            pagesize=landscape(A4),
            rightMargin=15 * mm,
            leftMargin=15 * mm,
            topMargin=15 * mm,
            bottomMargin=15 * mm,
        )

        styles = getSampleStyleSheet()

        title_style = ParagraphStyle(
            "ReportTitle",
            parent=styles["Title"],
            alignment=TA_CENTER,
            fontSize=20,
            spaceAfter=8,
        )

        normal_style = ParagraphStyle(
            "ReportNormal",
            parent=styles["Normal"],
            fontSize=9,
        )

        elements = []

        elements.append(
            Paragraph(
                f"Sellify - {table_name} Report",
                title_style
            )
        )

        elements.append(
            Paragraph(
                f"Report Period: "
                f"{report_start} to "
                f"{report_end - timedelta(days=1)}",
                normal_style
            )
        )

        elements.append(
            Paragraph(
                f"Generated By: {generated_by_name}",
                normal_style
            )
        )

        elements.append(
            Paragraph(
                f"Total Records: {len(rows)}",
                normal_style
            )
        )

        elements.append(
            Spacer(1, 10)
        )

        if rows:

            columns = list(rows[0].keys())

            header = [
                Paragraph(
                    str(column),
                    ParagraphStyle(
                        "Header",
                        parent=normal_style,
                        fontName="Helvetica-Bold",
                    )
                )
                for column in columns
            ]

            table_data = [header]

            for row in rows:

                table_data.append(
                    [
                        Paragraph(
                            str(row[column])
                            if row[column] is not None
                            else "",
                            normal_style
                        )
                        for column in columns
                    ]
                )

            table = Table(
                table_data,
                repeatRows=1,
            )

            table.setStyle(
                TableStyle(
                    [
                        (
                            "BACKGROUND",
                            (0, 0),
                            (-1, 0),
                            colors.HexColor("#1976D2"),
                        ),
                        (
                            "TEXTCOLOR",
                            (0, 0),
                            (-1, 0),
                            colors.white,
                        ),
                        (
                            "GRID",
                            (0, 0),
                            (-1, -1),
                            0.5,
                            colors.grey,
                        ),
                        (
                            "VALIGN",
                            (0, 0),
                            (-1, -1),
                            "TOP",
                        ),
                        (
                            "LEFTPADDING",
                            (0, 0),
                            (-1, -1),
                            6,
                        ),
                        (
                            "RIGHTPADDING",
                            (0, 0),
                            (-1, -1),
                            6,
                        ),
                        (
                            "TOPPADDING",
                            (0, 0),
                            (-1, -1),
                            5,
                        ),
                        (
                            "BOTTOMPADDING",
                            (0, 0),
                            (-1, -1),
                            5,
                        ),
                    ]
                )
            )

            elements.append(table)

        else:

            elements.append(
                Paragraph(
                    "No records found for the selected period.",
                    normal_style
                )
            )

        document.build(elements)

        pdf_buffer.seek(0)

        filename = (
            f"{table_name.lower()}_"
            f"{period}_report.pdf"
        )

        return StreamingResponse(
            pdf_buffer,
            media_type="application/pdf",
            headers={
                "Content-Disposition":
                    f'attachment; filename="{filename}"'
            },
        )

    except HTTPException:
        raise

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=str(e)
        )
