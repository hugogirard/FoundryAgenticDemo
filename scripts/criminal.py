import json
from pathlib import Path
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT, TA_JUSTIFY
import random

def get_random_personality_trait():
    """Generate random personality traits for suspects"""
    traits = [
        "Known for excessive cheese wheel consumption during heists",
        "Has an unhealthy obsession with sweetrolls",
        "Frequently quotes 'I used to be an adventurer like you'",
        "Terrible at sneaking despite being a thief",
        "Believes buckets make them invisible",
        "Collects cabbages obsessively",
        "Afraid of chickens (especially in Riverwood)",
        "Claims to know the Cloud District very well",
        "Suspicious amount of iron daggers in inventory",
        "Has been arrested for the same crime 47 times",
        "Terrible liar - always looks at feet when questioned",
        "Compulsive hoarder of lockpicks and wooden plates",
        "Allergic to honest work",
        "Last seen carrying 2000 pounds of cheese",
        "Believes guards can't see them while crouching"
    ]
    return random.choice(traits)

def get_random_known_associate():
    """Generate funny known associates"""
    associates = [
        "A mudcrab merchant (allegedly)",
        "Nazeem (claims to know Cloud District)",
        "M'aiq the Liar",
        "A particularly aggressive chicken",
        "The Adoring Fan",
        "A suspicious Khajiit caravan",
        "Lydia (sworn to carry their burdens)",
        "A cheese wheel enthusiast club",
        "The Dark Brotherhood (membership pending)",
        "A group of disgruntled sweetroll victims",
        "Parthuurnax (citation needed)",
        "A talking dog outside Falkreath",
        "Several confused mudcrabs"
    ]
    return random.choice(associates)

def get_random_weakness():
    """Generate funny weaknesses"""
    weaknesses = [
        "Cannot resist stealing cheese wheels",
        "Stops all criminal activity to pick up every single coin",
        "Fascinated by butterfly wings",
        "Will pause mid-heist to read any book",
        "Terrible at bartering - always pays too much",
        "Gets distracted by anyone playing lute",
        "Stops to pick flowers during escape",
        "Addicted to skooma (obviously)",
        "Cannot walk past alchemy ingredients",
        "Compelled to take every single fork and knife",
        "Stops running to pick up calipers",
        "Easily distracted by shiny objects",
        "Must organize inventory during combat"
    ]
    return random.choice(weaknesses)

def get_threat_level(reward):
    """Determine threat level based on reward"""
    if reward >= 2000:
        return "EXTREMELY DANGEROUS", colors.HexColor('#8B0000')
    elif reward >= 1500:
        return "VERY DANGEROUS", colors.HexColor('#CD5C5C')
    elif reward >= 1000:
        return "DANGEROUS", colors.HexColor('#FF6347')
    elif reward >= 500:
        return "MODERATE THREAT", colors.HexColor('#FFA500')
    else:
        return "LOW THREAT", colors.HexColor('#FFD700')

def create_suspect_dossier(suspect_name, crimes, output_dir):
    """Create a detailed dossier for a specific suspect"""
    # Create filename
    safe_name = suspect_name.replace(" ", "_").replace("'", "")
    filename = output_dir / f"dossier_{safe_name}.pdf"
    
    # Create PDF document
    doc = SimpleDocTemplate(str(filename), pagesize=letter,
                           rightMargin=0.75*inch, leftMargin=0.75*inch,
                           topMargin=0.75*inch, bottomMargin=0.75*inch)
    
    elements = []
    styles = getSampleStyleSheet()
    
    # Custom styles
    title_style = ParagraphStyle(
        'DossierTitle',
        parent=styles['Heading1'],
        fontSize=26,
        textColor=colors.HexColor('#8B0000'),
        spaceAfter=10,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    classified_style = ParagraphStyle(
        'Classified',
        parent=styles['Normal'],
        fontSize=10,
        textColor=colors.red,
        alignment=TA_CENTER,
        fontName='Helvetica-Bold'
    )
    
    heading_style = ParagraphStyle(
        'SectionHeading',
        parent=styles['Heading2'],
        fontSize=14,
        textColor=colors.HexColor('#000080'),
        spaceAfter=8,
        spaceBefore=12,
        fontName='Helvetica-Bold'
    )
    
    body_style = ParagraphStyle(
        'BodyText',
        parent=styles['Normal'],
        fontSize=10,
        leading=14,
        alignment=TA_JUSTIFY
    )
    
    # Calculate total bounty
    total_bounty = sum(crime['reward'] for crime in crimes)
    threat_level, threat_color = get_threat_level(total_bounty)
    
    # Header
    elements.append(Paragraph("★ CONFIDENTIAL CRIMINAL DOSSIER ★", classified_style))
    elements.append(Spacer(1, 0.1*inch))
    elements.append(Paragraph(suspect_name.upper(), title_style))
    elements.append(Spacer(1, 0.05*inch))
    
    # Threat level box
    threat_style = ParagraphStyle('Threat', parent=styles['Normal'], 
                                  fontSize=14, textColor=threat_color, 
                                  alignment=TA_CENTER, fontName='Helvetica-Bold')
    elements.append(Paragraph(f"⚠ THREAT LEVEL: {threat_level} ⚠", threat_style))
    elements.append(Spacer(1, 0.2*inch))
    
    # Basic Information Box
    elements.append(Paragraph("═══ SUSPECT IDENTIFICATION ═══", heading_style))
    
    # Get description from first crime
    description = crimes[0]['description']
    cities = list(set(crime['city'] for crime in crimes))
    
    info_data = [
        ["Full Name:", suspect_name],
        ["Physical Description:", description],
        ["Total Bounty:", f"{total_bounty} Gold Septims"],
        ["Number of Crimes:", f"{len(crimes)} confirmed offenses"],
        ["Known Locations:", ", ".join(cities)],
        ["Status:", "AT LARGE - Armed and Dangerous (probably)"]
    ]
    
    info_table = Table(info_data, colWidths=[2*inch, 4.5*inch])
    info_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (0, -1), colors.HexColor('#E8E8E8')),
        ('TEXTCOLOR', (0, 0), (-1, -1), colors.black),
        ('ALIGN', (0, 0), (0, -1), 'RIGHT'),
        ('ALIGN', (1, 0), (1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (0, -1), 'Helvetica-Bold'),
        ('FONTNAME', (1, 0), (1, -1), 'Helvetica'),
        ('FONTSIZE', (0, 0), (-1, -1), 9),
        ('GRID', (0, 0), (-1, -1), 1, colors.black),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('LEFTPADDING', (0, 0), (-1, -1), 8),
        ('RIGHTPADDING', (0, 0), (-1, -1), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 6),
        ('BOTTOMPADDING', (0, 0), (-1, -1), 6),
    ]))
    elements.append(info_table)
    elements.append(Spacer(1, 0.2*inch))
    
    # Psychological Profile (the funny part!)
    elements.append(Paragraph("═══ PSYCHOLOGICAL PROFILE ═══", heading_style))
    
    personality = get_random_personality_trait()
    associate = get_random_known_associate()
    weakness = get_random_weakness()
    
    profile_text = f"""
    <b>Personality Assessment:</b> {personality}<br/>
    <br/>
    <b>Known Associates:</b> {associate}<br/>
    <br/>
    <b>Identified Weakness:</b> {weakness}<br/>
    <br/>
    <b>Guard's Notes:</b> "I've been on the lookout for this one. Caused quite a stir. 
    Probably took an arrow to the knee at some point, but that hasn't stopped them from their 
    life of crime. Handle with caution - may attempt to fast-travel during arrest."
    """
    
    elements.append(Paragraph(profile_text, body_style))
    elements.append(Spacer(1, 0.2*inch))
    
    # Criminal Record
    elements.append(Paragraph("═══ CRIMINAL RECORD ═══", heading_style))
    
    crime_cell_style = ParagraphStyle('CrimeCell', parent=styles['Normal'],
                                     fontSize=8, leading=10, alignment=TA_LEFT)
    
    crime_data = [["Crime Committed", "Location", "Bounty", "Type"]]
    
    for crime in crimes:
        crime_data.append([
            Paragraph(crime['crimeName'], crime_cell_style),
            Paragraph(crime['city'], crime_cell_style),
            Paragraph(f"{crime['reward']} Gold", crime_cell_style),
            Paragraph(crime['crimeType'].replace('_', ' ').title(), crime_cell_style)
        ])
    
    crime_table = Table(crime_data, colWidths=[2.5*inch, 1.5*inch, 1*inch, 1.5*inch])
    crime_table.setStyle(TableStyle([
        ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#8B0000')),
        ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
        ('ALIGN', (0, 0), (-1, -1), 'LEFT'),
        ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
        ('FONTSIZE', (0, 0), (-1, 0), 9),
        ('BOTTOMPADDING', (0, 0), (-1, 0), 8),
        ('TOPPADDING', (0, 0), (-1, -1), 4),
        ('BOTTOMPADDING', (0, 1), (-1, -1), 4),
        ('GRID', (0, 0), (-1, -1), 0.5, colors.black),
        ('VALIGN', (0, 0), (-1, -1), 'TOP'),
        ('ROWBACKGROUNDS', (0, 1), (-1, -1), [colors.white, colors.HexColor('#F5F5F5')])
    ]))
    
    elements.append(crime_table)
    elements.append(Spacer(1, 0.2*inch))
    
    # Apprehension Instructions
    elements.append(Paragraph("═══ APPREHENSION INSTRUCTIONS ═══", heading_style))
    
    instructions = f"""
    <b>DO NOT ENGAGE ALONE!</b> This suspect is wanted for {len(crimes)} separate offenses 
    across multiple holds. Approach with extreme caution and preferably with backup.<br/>
    <br/>
    <b>Capture Reward:</b> {total_bounty} Gold Septims (Dead or Alive - but preferably alive 
    because paperwork)<br/>
    <br/>
    <b>Contact:</b> Report all sightings immediately to your local Jarl's Guard or Hold Guard. 
    Do not attempt to claim bounty without proper evidence of capture.<br/>
    <br/>
    <b>Warning:</b> Suspect may attempt to crouch in corner thinking they cannot be seen. 
    May also try to put bucket on your head. Stay alert!
    """
    
    elements.append(Paragraph(instructions, body_style))
    elements.append(Spacer(1, 0.15*inch))
    
    # Footer
    elements.append(HRFlowable(width="100%", thickness=1, color=colors.black))
    elements.append(Spacer(1, 0.1*inch))
    
    footer_style = ParagraphStyle('Footer', parent=styles['Italic'],
                                 fontSize=7, textColor=colors.grey, alignment=TA_CENTER)
    footer_text = (
        f"Dossier ID: SKY-{hash(suspect_name) % 100000:05d} | "
        f"Classification: CONFIDENTIAL | "
        f"By Order of the Jarl | "
        f"May Talos guide you"
    )
    elements.append(Paragraph(footer_text, footer_style))
    
    # Build PDF
    doc.build(elements)
    print(f"  Created dossier: {safe_name}")

def main():
    # Set random seed for consistent but varied results
    random.seed(42)
    
    # Load crime data
    crime_file = Path("../dataset/crimes.json")
    
    if not crime_file.exists():
        print(f"Error: {crime_file} not found!")
        return
    
    with open(crime_file, 'r') as f:
        crimes = json.load(f)
    
    print(f"Loaded {len(crimes)} crimes from {crime_file}")
    
    # Create output directory
    output_dir = Path("pdf/dossiers")
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Group crimes by suspect
    crimes_by_suspect = {}
    for crime in crimes:
        suspect = crime['suspectName']
        if suspect not in crimes_by_suspect:
            crimes_by_suspect[suspect] = []
        crimes_by_suspect[suspect].append(crime)
    
    print(f"\nFound {len(crimes_by_suspect)} unique suspects")
    print("\nGenerating suspect dossiers...")
    
    # Create a dossier for each suspect
    for suspect_name, suspect_crimes in crimes_by_suspect.items():
        create_suspect_dossier(suspect_name, suspect_crimes, output_dir)
    
    print(f"\n✓ All {len(crimes_by_suspect)} dossiers created successfully!")
    print(f"✓ Location: {output_dir}/")
    
    # Summary statistics
    print("\n═══ DOSSIER GENERATION SUMMARY ═══")
    multi_crime_suspects = [s for s, c in crimes_by_suspect.items() if len(c) > 1]
    print(f"Repeat offenders: {len(multi_crime_suspects)}")
    
    highest_bounty = max(crimes_by_suspect.items(), 
                        key=lambda x: sum(c['reward'] for c in x[1]))
    total = sum(c['reward'] for c in highest_bounty[1])
    print(f"Most wanted: {highest_bounty[0]} ({total} Gold)")
    print(f"\nMay the Nine Divines guide the guards in their pursuit!")

if __name__ == "__main__":
    main()