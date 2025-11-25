#!/usr/bin/env python3
"""Show detailed OCR extraction results"""

import json

with open('/tmp/all_employees.json', 'r', encoding='utf-8') as f:
    employees = json.load(f)

print("=" * 80)
print("📊 CLAUDE OCR KIOLVASÁSI EREDMÉNYEK")
print("=" * 80)
print()

# Show 3 employees in full detail
for i, emp in enumerate(employees[:3], 1):
    print(f"\n{'━' * 80}")
    print(f"👤 {i}. MUNKAVÁLLALÓ: {emp['name']}")
    print(f"{'━' * 80}")
    print(f"📅 Heti óraszám: {emp.get('weekly_hours', 'N/A')}")
    print(f"📋 Műszakok száma: {len(emp.get('shifts', []))}")
    print()

    for shift in emp.get('shifts', []):
        date = shift.get('date')
        day = shift.get('day')
        shift_type = shift.get('type')
        position = shift.get('position')
        start = shift.get('start_time', '')
        end = shift.get('end_time', '')
        hours = shift.get('hours', '')
        details = shift.get('details', '')

        if shift_type == 'shift':
            time_str = f"{start}-{end}" if start and end else ""
            hours_str = f" ({hours})" if hours else ""
            print(f"   📍 {date} ({day}): {position} {time_str}{hours_str}")
            if details:
                print(f"      💡 Részletek: {details}")
        elif shift_type == 'rest':
            print(f"   🏖️  {date} ({day}): Pihenőnap")
        elif shift_type == 'holiday':
            print(f"   🎉 {date} ({day}): Munkaszüneti nap")
        elif shift_type == 'sick':
            print(f"   🏥 {date} ({day}): Beteg/Szabadság")

# Summary of all employees
print(f"\n\n{'=' * 80}")
print(f"📊 ÖSSZESÍTÉS - MIND A {len(employees)} MUNKAVÁLLALÓ")
print(f"{'=' * 80}")
print()

for i, emp in enumerate(employees, 1):
    name = emp['name']
    weekly_hours = emp.get('weekly_hours', 'N/A')
    shift_count = len(emp.get('shifts', []))

    # Count shift types
    shifts = emp.get('shifts', [])
    work_shifts = sum(1 for s in shifts if s.get('type') == 'shift')
    rest_days = sum(1 for s in shifts if s.get('type') == 'rest')
    holidays = sum(1 for s in shifts if s.get('type') == 'holiday')
    sick_days = sum(1 for s in shifts if s.get('type') == 'sick')

    print(f"{i:2d}. {name:40s} | {weekly_hours:>6s} óra/hét | ", end="")
    print(f"Műszak: {work_shifts}, Pihenő: {rest_days}, Beteg: {sick_days}, Ünnep: {holidays}")

print(f"\n{'=' * 80}")
print(f"✅ SIKERES OCR: {len(employees)} munkavállaló teljes heti beosztása!")
print(f"{'=' * 80}")
