#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable


READ_ENCODINGS = ("utf-8-sig", "utf-8", "cp950", "big5")


@dataclass
class StockRecord:
    date: str
    open: float
    high: float
    low: float
    close: float
    adjust_close: float
    volume: int


@dataclass
class AnnualSummary:
    year: str
    volume: int
    amount: float
    trades: int
    high: float
    high_date: str
    low: float
    low_date: str
    average_close: float


@dataclass
class MonthlySummary:
    year: str
    month: str
    high: float
    low: float
    weighted_average: float
    trades: int
    amount: float
    volume: int
    turnover_rate: float


def read_text_with_fallback(path: Path) -> str:
    for encoding in READ_ENCODINGS:
        try:
            return path.read_text(encoding=encoding)
        except UnicodeDecodeError:
            continue
    raise UnicodeDecodeError("unknown", b"", 0, 1, f"Unable to decode: {path}")


def normalize_csv_encoding(path: Path, target_encoding: str = "utf-8-sig") -> bool:
    text = read_text_with_fallback(path)
    current = path.read_bytes()
    updated = text.encode(target_encoding)
    if current == updated:
        return False
    path.write_bytes(updated)
    return True


def roc_to_ad_date(raw: str) -> str:
    # input sample: " 99/01/04"
    cleaned = raw.strip().replace('"', "")
    parts = cleaned.split("/")
    if len(parts) != 3:
        raise ValueError(f"Unexpected date format: {raw!r}")
    roc_year, month, day = parts
    ad_year = int(roc_year) + 1911
    return f"{ad_year:04d}/{int(month):02d}/{int(day):02d}"


def roc_year_to_ad(raw: str) -> str:
    value = raw.strip().replace('"', "")
    return str(int(value) + 1911)


def parse_number(raw: str, is_int: bool = False) -> float | int | None:
    value = raw.strip().replace(",", "").replace('"', "")
    if not value or value == "--":
        return None
    if is_int:
        return int(float(value))
    return float(value)


def parse_csv_records(csv_path: Path) -> list[StockRecord]:
    text = read_text_with_fallback(csv_path)
    rows = list(csv.reader(text.splitlines()))
    parsed: list[StockRecord] = []

    for row in rows[2:]:
        if len(row) < 7:
            continue
        try:
            date = roc_to_ad_date(row[0])
            volume = parse_number(row[1], is_int=True)
            open_price = parse_number(row[3])
            high = parse_number(row[4])
            low = parse_number(row[5])
            close = parse_number(row[6])
        except ValueError:
            continue

        if None in (volume, open_price, high, low, close):
            continue

        close_value = float(close)
        parsed.append(
            StockRecord(
                date=date,
                open=float(open_price),
                high=float(high),
                low=float(low),
                close=close_value,
                adjust_close=close_value,
                volume=int(volume),
            )
        )
    return parsed


def parse_annual_summaries(csv_dir: Path) -> list[AnnualSummary]:
    annual_files = sorted(csv_dir.glob("FMNPTK_*.csv"))
    if not annual_files:
        return []
    rows = list(csv.reader(read_text_with_fallback(annual_files[0]).splitlines()))
    summaries: list[AnnualSummary] = []
    for row in rows[2:]:
        if len(row) < 9:
            continue
        year = roc_year_to_ad(row[0])
        volume = parse_number(row[1], is_int=True)
        amount = parse_number(row[2])
        trades = parse_number(row[3], is_int=True)
        high = parse_number(row[4])
        high_date = row[5].strip().replace('"', "")
        low = parse_number(row[6])
        low_date = row[7].strip().replace('"', "")
        average_close = parse_number(row[8])
        if None in (volume, amount, trades, high, low, average_close):
            continue
        summaries.append(
            AnnualSummary(
                year=year,
                volume=int(volume),
                amount=float(amount),
                trades=int(trades),
                high=float(high),
                high_date=high_date,
                low=float(low),
                low_date=low_date,
                average_close=float(average_close),
            )
        )
    summaries.sort(key=lambda item: item.year, reverse=True)
    return summaries


def parse_monthly_summaries(csv_dir: Path) -> list[MonthlySummary]:
    summaries: list[MonthlySummary] = []
    for csv_path in sorted(csv_dir.glob("FMSRFK_*.csv")):
        rows = list(csv.reader(read_text_with_fallback(csv_path).splitlines()))
        for row in rows[2:]:
            if len(row) < 9:
                continue
            year = roc_year_to_ad(row[0])
            month_raw = row[1].strip().replace('"', "")
            month = f"{int(month_raw):02d}"
            high = parse_number(row[2])
            low = parse_number(row[3])
            weighted_average = parse_number(row[4])
            trades = parse_number(row[5], is_int=True)
            amount = parse_number(row[6])
            volume = parse_number(row[7], is_int=True)
            turnover_rate = parse_number(row[8])
            if None in (high, low, weighted_average, trades, amount, volume, turnover_rate):
                continue
            summaries.append(
                MonthlySummary(
                    year=year,
                    month=month,
                    high=float(high),
                    low=float(low),
                    weighted_average=float(weighted_average),
                    trades=int(trades),
                    amount=float(amount),
                    volume=int(volume),
                    turnover_rate=float(turnover_rate),
                )
            )
    summaries.sort(key=lambda item: (item.year, item.month), reverse=True)
    return summaries


def build_history_json(csv_dir: Path, output_json: Path) -> int:
    all_records: list[StockRecord] = []
    for csv_file in sorted(csv_dir.glob("STOCK_DAY_*.csv")):
        all_records.extend(parse_csv_records(csv_file))
    annual_summaries = parse_annual_summaries(csv_dir)
    monthly_summaries = parse_monthly_summaries(csv_dir)

    all_records.sort(key=lambda r: r.date, reverse=True)
    payload = {
        "records": [record.__dict__ for record in all_records],
        "dividends": [],
        "annual_summaries": [item.__dict__ for item in annual_summaries],
        "monthly_summaries": [item.__dict__ for item in monthly_summaries],
    }
    output_json.write_text(
        json.dumps(payload, ensure_ascii=False, indent=4) + "\n",
        encoding="utf-8",
    )
    return len(all_records)


def normalize_folder(csv_dir: Path) -> int:
    count = 0
    for csv_file in csv_dir.glob("*.csv"):
        if normalize_csv_encoding(csv_file):
            count += 1
    return count


def run_pipeline(pairs: Iterable[tuple[Path, Path]], normalize: bool) -> None:
    for csv_dir, json_out in pairs:
        if normalize:
            changed = normalize_folder(csv_dir)
            print(f"[normalize] {csv_dir}: {changed} files converted to utf-8-sig")
        total = build_history_json(csv_dir, json_out)
        print(f"[json] {json_out}: {total} records")


def main() -> None:
    parser = argparse.ArgumentParser(description="Normalize stock CSV encoding and build history JSON.")
    parser.add_argument("--normalize", action="store_true", help="Convert CSV files to UTF-8 with BOM.")
    parser.add_argument("--root", type=Path, default=Path.cwd(), help="Project root.")
    args = parser.parse_args()

    root = args.root.resolve()
    pairs = [
        (root / "0050_history", root / "Compound Interest" / "0050_history.json"),
        (root / "2330_history", root / "Compound Interest" / "2330_history.json"),
    ]
    run_pipeline(pairs, normalize=args.normalize)


if __name__ == "__main__":
    main()
