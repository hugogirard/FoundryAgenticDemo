import json
from pathlib import Path
from reportlab.lib.pagesizes import letter, A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT

def get_crime_penalties():
    """Define penalties and reporting information for each crime type"""
    return {
        "pettyTheft": {
            "penalty": "50 Gold Fine or 7 Days in Jail",
            "reporting_authority": "Local City Guard or Jarl's Steward",
            "additional_info": "Petty theft includes stolen items worth less than 500 gold. Repeat offenders may face increased penalties."
        },
        "grandTheft": {
            "penalty": "500 Gold Fine or 30 Days in Jail",
            "reporting_authority": "City Guard Captain or Jarl",
            "additional_info": "Grand theft applies to stolen items worth 500 gold or more, including artifacts, relics, and valuable goods."
        },
        "arson": {
            "penalty": "1000 Gold Fine or 60 Days in Jail, plus restitution",
            "reporting_authority": "Jarl and City Guard Immediately",
            "additional_info": "Arson is a severe crime. Offenders must pay for reconstruction costs and face potential banishment."
        },
        "poisoning": {
            "penalty": "750 Gold Fine or 45 Days in Jail",
            "reporting_authority": "City Guard and Court Wizard",
            "additional_info": "Poisoning attempts are taken seriously. Victims must receive immediate alchemical treatment at offender's expense."
        },
        "robbery": {
            "penalty": "600 Gold Fine or 40 Days in Jail",
            "reporting_authority": "Local City Guard or Hold Guard",
            "additional_info": "Robbery involves theft with intimidation or force. Stolen goods must be returned or compensated."
        },
        "propertyDamage": {
            "penalty": "200 Gold Fine or 14 Days in Jail, plus repair costs",
            "reporting_authority": "Property Owner and City Guard",
            "additional_info": "All damages must be repaired or compensated. Costs vary based on extent of destruction."
        },
        "heresy": {
            "penalty": "1500 Gold Fine or 90 Days in Jail, possible banishment",
            "reporting_authority": "Temple Priests and Jarl",
            "additional_info": "Daedric worship and illegal religious practices threaten the social order. Severe cases may result in exile."
        },
        "assault": {
            "penalty": "400 Gold Fine or 25 Days in Jail",
            "reporting_authority": "City Guard Immediately",
            "additional_info": "Physical assault on citizens is strictly prohibited. Medical costs must be covered by the offender."
        },
        "forgery": {
            "penalty": "300 Gold Fine or 20 Days in Jail",
            "reporting_authority": "Jarl's Steward or Court Official",
            "additional_info": "Forged documents undermine legal authority. All false documents will be destroyed."
        },
        "smuggling": {
            "penalty": "800 Gold Fine or 50 Days in Jail, goods confiscated",
            "reporting_authority": "City Guard and Trade Officials",
            "additional_info": "Smuggled goods are subject to confiscation. Repeat offenders face permanent trade bans."
        },
        "minorOffense": {
            "penalty": "25 Gold Fine or 3 Days in Jail",
            "reporting_authority": "Any City Guard",
            "additional_info": "Minor offenses include public disturbances, unauthorized activities, and petty infractions."
        },
        "murder": {
            "penalty": "Death or Life Imprisonment",
            "reporting_authority": "Jarl and Hold Guard Commander Immediately",
            "additional_info": "Murder is the most serious crime in Skyrim. Swift justice will be delivered by the Jarl's authority."
        }
    }

def create_crime_type_pdf(crime_type, crimes, penalty_info, output_dir):
    """Create a PDF for a specific crime type"""
    # Create filename
    filename = output_dir / f"{crime_type}_penalties.pdf"
    
    # Create PDF document with A4 size for more width
    doc = SimpleDocTemplate(str(filename), pagesize=letter,
                           rightMargin=0.5*inch, leftMargin=0.5*inch,
                           topMargin=0.75*inch, bottomMargin=0.5*inch)
    
    # Container for the 'Flowable' objects
    elements = []
    
    # Define styles
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        'CustomTitle',
        parent=styles['Heading1'],
        fontSize=22,
        textColor=colors.HexColor('#8B0000'),
        spaceAfter=20,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading_style = ParagraphStyle(
        'CustomHeading',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#000080'),
        spaceAfter=10,
        spaceBefore=10,
        fontName='Helvetica-Bold'
    )
    
    # Add title
    title_text = crime_type.replace('_', ' ').title()
    title = Paragraph(f"SKYRIM CRIMINAL CODE: {title_text}", title_style)
    elements.append(title)
    elements.append(Spacer(1, 0.15*inch))
    
    # Add penalty information
    elements.append(Paragraph("OFFICIAL PENALTY INFORMATION", heading_style))
    
    penalty_data = [
        ["Penalty:", penalty_info["penalty"]],
        ["Report To:", penalty_info["reporting_authority"]],
        ["Additional Info:", penalty_info["additional_info"]]
    ]
    
    penalty_table = Table(penalty_data, colWidths=[1.3*inch, 5.7*inch])
    penalty_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#D3D3D3')),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
        ('ALIGN', (1, 0), (1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 6),
        ('RIGHTPADDING', (0, 0), (-1, -1), 6),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    
    elements.append(penalty_table)
    elements.append(Spacer(1, 0.25*inch))
    
    # Add wanted list
    elements.append(Paragraph(f"WANTED CRIMINALS ({len(crimes)} Active Warrants)", heading_style))
    elements.append(Spacer(1, 0.1*inch))
    
    # Create table with crime details using Paragraph for text wrapping
    table_data = [["Crime", "Suspect", "City", "Reward", "Description"]]
    
    # Style for table cells
    cell_style = ParagraphStyle(
        'CellStyle',
        parent=styles['Normal'],
        fontSize=8,
        leading=10,
        alignment=TA_LEFT
    )
    
    for crime in crimes:
        table_data.append([
            Paragraph(crime["crimeName"], cell_style),
            Paragraph(crime["suspectName"], cell_style),
            Paragraph(crime["city"], cell_style),
            Paragraph(f"{crime['reward']} Gold", cell_style),
            Paragraph(crime["description"], cell_style)
        ])
    
    # Create table with adjusted column widths
    crime_table = Table(table_data, colWidths=[1.8*inch, 1.3*inch, 0.9*inch, 0.7*inch, 2.3*inch])
    crime_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#8B0000')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 10),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 10),
        ('TOPPADDING', (0, 0), (-1, -1), 5),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 5),
        ('LEFTPADDING', (0, 0), (-1, -1), 4),
        ('RIGHTPADDING', (0, 0), (-1, -1), 4),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.black),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F5F5F5')])
    ]))
    
    elements.append(crime_table)
    
    # Add footer note
    elements.append(Spacer(1, 0.2*inch))
    footer_style = ParagraphStyle(
        'FooterStyle',
        parent=styles['Italic'],
        fontSize=8,
        textColor=colors.HexColor('#333333')
    )
    footer_text = (
        "By order of the Jarl, all citizens are required to report any information "
        "regarding these criminals to the proper authorities. Bounties will be paid upon "
        "successful apprehension or confirmed elimination of the suspect."
    )
    elements.append(Paragraph(footer_text, footer_style))
    
    # Build PDF
    doc.build(elements)
    print(f"Created: {filename}")

def main():
    # Load crime data
    crime_file = Path("../dataset/crimes.json")
    
    if not crime_file.exists():
        print(f"Error: {crime_file} not found!")
        print("Please ensure crime.json exists in the current directory.")
        return
    
    with open(crime_file, 'r') as f:
        crimes = json.load(f)
    
    print(f"Loaded {len(crimes)} crimes from {crime_file}")
    
    # Create output directory
    output_dir = Path("pdf")
    output_dir.mkdir(exist_ok=True)
    
    # Get penalty information
    penalties = get_crime_penalties()
    
    # Group crimes by type
    crimes_by_type = {}
    for crime in crimes:
        crime_type = crime["crimeType"]
        if crime_type not in crimes_by_type:
            crimes_by_type[crime_type] = []
        crimes_by_type[crime_type].append(crime)
    
    print(f"\nFound {len(crimes_by_type)} different crime types:")
    for crime_type, crime_list in crimes_by_type.items():
        print(f"  - {crime_type}: {len(crime_list)} crimes")
    
    print("\nGenerating PDFs...")
    
    # Create a PDF for each crime type
    for crime_type, crime_list in crimes_by_type.items():
        if crime_type in penalties:
            create_crime_type_pdf(crime_type, crime_list, penalties[crime_type], output_dir)
        else:
            print(f"Warning: No penalty info defined for {crime_type}")
    
    print(f"\nAll PDFs created successfully in the '{output_dir}' directory!")
    print("\nCrime Type Summary:")
    for crime_type in sorted(crimes_by_type.keys()):
        print(f"  {crime_type}: {penalties.get(crime_type, {}).get('penalty', 'N/A')}")


if __name__ == "__main__":
    main()