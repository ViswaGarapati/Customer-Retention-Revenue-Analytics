"""Illustrative B2B subscriptions. Every bill covers one calendar month in INR."""
from datetime import date
import random

CHANNELS = ("Organic", "Partner", "Paid search")
PRICES = (49000, 149000, 399000)


def populate(db, seed=1927):
    rng = random.Random(seed)
    months = [date(2024 + i // 12, i % 12 + 1, 1).isoformat() for i in range(34)]
    db.executemany("INSERT INTO calendar VALUES (?,?)", enumerate_months(months))
    signups = rng.choices(range(len(months)), weights=range(50, 84), k=4200)
    invoices, events, attempts, accounts = [], [], [], []
    for account, start in enumerate(signups, 1):
        channel = rng.choices(CHANNELS, weights=(45, 25, 30))[0]
        accounts.append((account, channel, months[start]))
        tier = rng.choices(range(3), weights=(66, 27, 7))[0]
        previous = 0
        for i in range(start, len(months)):
            if i == start:
                active = True
            elif previous:
                hazard = {"Organic": .030, "Partner": .019, "Paid search": .048}[channel]
                active = rng.random() >= hazard * (1.45 if i-start <= 3 else 1)
                move = rng.random()
                tier = min(2, tier+1) if move < .037 else max(0, tier-1) if move > .98 else tier
            else:
                active = rng.random() < .021
            current = PRICES[tier] if active else 0
            if current != previous:
                events.append((account, months[i], current))
            if active:
                bill = len(invoices) + 1
                invoices.append((bill, account, months[i], current))
                failed = rng.random() < (.085 if channel == "Paid search" else .045)
                attempts.append((bill, 1, 0 if failed else current))
                if failed:
                    recovered = rng.random() < .68
                    attempts.append((bill, 2, current if recovered else 0))
            previous = current
    db.executemany("INSERT INTO account VALUES (?,?,?)", accounts)
    db.executemany("INSERT INTO contract_event VALUES (?,?,?)", events)
    db.executemany("INSERT INTO invoice VALUES (?,?,?,?)", invoices)
    db.executemany("INSERT INTO payment_attempt VALUES (?,?,?)", attempts)


def enumerate_months(months):
    return ((month, i) for i, month in enumerate(months))
