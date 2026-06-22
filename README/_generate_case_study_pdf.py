# -*- coding: utf-8 -*-
"""Case Study PDF generator — EN + TR"""
from pathlib import Path

from fpdf import FPDF

README_DIR = Path(__file__).resolve().parent
FONT_DIR = Path(r"C:\Windows\Fonts")
MARGIN = 18
WIDTH = 210 - 2 * MARGIN  # 174mm usable width


CONTENT = {
    "en": {
        "file": "Case Study EN.pdf",
        "cover_title": "Case Study",
        "cover_subtitle": "High-Performance Financial\nTransaction System",
        "summary_title": "Problem Statement",
        "summary": (
            "You are a Java Developer at a leading financial institution tasked with building "
            "a high-performance, scalable money transfer system that allows clients to view "
            "their account lists and transfer funds to other clients. The system must handle "
            "high concurrency, ensure data consistency, and integrate with multiple external "
            "services (e.g., fraud detection, notification services, ledger updates)."
        ),
        "tech_title": "Expected Technology Stack",
        "tech_items": [
            "Java / Spring Boot microservices",
            "Kafka for async messaging",
            "Redis for caching",
            "PostgreSQL for persistence",
            "Circuit breaker, retry, and idempotency",
        ],
        "req_title": "Key Requirements",
        "sections": [
            (
                "Account Management",
                [
                    "Fetch and display a list of accounts for a given client.",
                    "Account data must be cached for performance.",
                ],
            ),
            (
                "Money Transfer",
                [
                    "Support high-frequency transactions with low latency.",
                    "Ensure atomicity (transactions succeed or fail completely).",
                    "Handle retries in case of temporary failures (network issues, external service unavailability).",
                ],
            ),
            (
                "External Service Integration",
                [
                    "Fraud detection service (sync call, must be fast).",
                    "Notification service (async, eventual consistency).",
                    "Ledger service (must be eventually consistent).",
                ],
            ),
            (
                "Performance & Scalability",
                [
                    "Optimize for high throughput (thousands of transactions per second).",
                    "Use Kafka for async processing where possible.",
                    "Implement caching (Redis) to reduce database load.",
                ],
            ),
            (
                "Resilience",
                [
                    "Retry policies for transient failures (exponential backoff).",
                    "Circuit breakers to avoid cascading failures.",
                    "Idempotency to prevent duplicate transactions.",
                ],
            ),
        ],
        "eval_title": "Evaluation Criteria",
        "criteria": [
            ("Correctness", "No double-spending, data consistency."),
            ("Performance", "Handles 1,000+ TPS with low latency."),
            ("Resilience", "Retries, circuit breakers, idempotency."),
            ("Scalability", "Microservices, Kafka, caching."),
            ("Code Quality", "Clean architecture, tests, observability."),
        ],
        "bonus_title": "Bonus Challenges (Optional)",
        "bonus": [
            "How would you handle a partial failure where money is debited but not credited?",
            "How would you scale this globally (multi-region deployments)?",
            "How would you introduce rate limiting to prevent abuse?",
        ],
    },
    "tr": {
        "file": "Case Study TR.pdf",
        "cover_title": "Case Study",
        "cover_subtitle": "Yüksek Performanslı Finansal\nİşlem Sistemi",
        "summary_title": "Problem Tanımı",
        "summary": (
            "Önde gelen bir finans kuruluşunda Java geliştiricisi olarak, müşterilerin hesap "
            "listelerini görüntüleyebildiği ve birbirlerine para transferi yapabildiği yüksek "
            "performanslı, ölçeklenebilir bir para transferi sistemi kurmanız istenmektedir. "
            "Sistem yüksek eşzamanlılığı desteklemeli, veri tutarlılığını sağlamalı ve fraud "
            "tespiti, bildirim ve defter güncelleme gibi birden fazla dış servisle entegre "
            "çalışmalıdır."
        ),
        "tech_title": "Beklenen Teknoloji Yığını",
        "tech_items": [
            "Java / Spring Boot mikroservis mimarisi",
            "Kafka ile asenkron mesajlaşma",
            "Redis ile önbellekleme (cache)",
            "PostgreSQL ile kalıcı veri",
            "Circuit breaker, retry ve idempotency",
        ],
        "req_title": "Temel Gereksinimler",
        "sections": [
            (
                "Hesap Yönetimi",
                [
                    "Belirli bir müşteri için hesap listesini getirip göstermek.",
                    "Performans için hesap verilerinin önbellekte tutulması.",
                ],
            ),
            (
                "Para Transferi",
                [
                    "Yüksek frekanslı, düşük gecikmeli transfer işlemleri.",
                    "Atomiklik: işlem ya tamamen başarılı ya da tamamen başarısız olmalı.",
                    "Geçici hatalarda (ağ, dış servis) yeniden deneme (retry) desteği.",
                ],
            ),
            (
                "Dış Servis Entegrasyonu",
                [
                    "Fraud tespit servisi (senkron çağrı, hızlı olmalı).",
                    "Bildirim servisi (asenkron, eventual consistency).",
                    "Defter (ledger) servisi (eventually consistent olmalı).",
                ],
            ),
            (
                "Performans ve Ölçeklenebilirlik",
                [
                    "Yüksek throughput (saniyede binlerce işlem).",
                    "Mümkün olduğunca Kafka ile asenkron işleme.",
                    "Veritabanı yükünü azaltmak için Redis önbellekleme.",
                ],
            ),
            (
                "Dayanıklılık (Resilience)",
                [
                    "Geçici hatalar için retry politikası (üstel geri çekilme).",
                    "Zincirleme hataları önlemek için circuit breaker.",
                    "Çift işlemi önlemek için idempotency.",
                ],
            ),
        ],
        "eval_title": "Değerlendirme Kriterleri",
        "criteria": [
            ("Doğruluk", "Çift harcama olmamalı; veri tutarlılığı korunmalı."),
            ("Performans", "1000+ TPS ve düşük gecikme hedeflenmeli."),
            ("Dayanıklılık", "Retry, circuit breaker ve idempotency uygulanmalı."),
            ("Ölçeklenebilirlik", "Mikroservisler, Kafka ve önbellekleme kullanılmalı."),
            ("Kod Kalitesi", "Temiz mimari, testler ve gözlemlenebilirlik."),
        ],
        "bonus_title": "Bonus Sorular (Opsiyonel)",
        "bonus": [
            "Para çekildi ancak karşı tarafa yansımadıysa (kısmi başarısızlık) nasıl ele alınır?",
            "Sistemi global ölçekte (çok bölgeli deployment) nasıl ölçeklendirirsiniz?",
            "Kötüye kullanımı önlemek için rate limiting nasıl tasarlanır?",
        ],
    },
}


class CaseStudyPDF(FPDF):
    def __init__(self, page_label: str = "Sayfa"):
        super().__init__()
        self.page_label = page_label

    def footer(self):
        self.set_y(-14)
        self.set_font("Arial", "I", 10)
        self.set_text_color(120, 120, 120)
        self.cell(0, 10, f"{self.page_label} {self.page_no()}/{{nb}}", align="C")

    def page_heading(self, title: str):
        """Sayfa basligi — kayma olmamasi icin tek blok."""
        self.set_font("Arial", "B", 20)
        self.set_text_color(30, 64, 115)
        self.set_x(MARGIN)
        self.multi_cell(WIDTH, 11, title)
        self.ln(4)
        self.set_draw_color(30, 64, 115)
        self.set_line_width(0.8)
        y = self.get_y()
        self.line(MARGIN, y, MARGIN + WIDTH, y)
        self.ln(6)

    def section_title(self, num: int, title: str):
        self.ln(2)
        self.set_fill_color(30, 64, 115)
        self.set_text_color(255, 255, 255)
        self.set_font("Arial", "B", 14)
        self.set_x(MARGIN)
        self.multi_cell(WIDTH, 10, f"  {num}. {title}", fill=True)
        self.ln(3)
        self.set_text_color(40, 40, 40)

    def bullet(self, text: str):
        self.set_x(MARGIN + 4)
        self.set_font("Arial", "", 12.5)
        bullet_w = 8
        self.cell(bullet_w, 7, "-")
        self.multi_cell(WIDTH - bullet_w - 4, 7, text)


def add_fonts(pdf: FPDF) -> None:
    for style, suffix in [("", "arial.ttf"), ("B", "arialbd.ttf"), ("I", "ariali.ttf")]:
        pdf.add_font("Arial", style, str(FONT_DIR / suffix))


def build(lang: str) -> Path:
    data = CONTENT[lang]
    pdf = CaseStudyPDF(page_label="Page" if lang == "en" else "Sayfa")
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=20)
    pdf.set_margins(MARGIN, MARGIN, MARGIN)
    add_fonts(pdf)

    # --- Kapak ---
    pdf.add_page()
    pdf.set_fill_color(30, 64, 115)
    pdf.rect(0, 0, 210, 82, style="F")
    pdf.set_y(28)
    pdf.set_font("Arial", "B", 32)
    pdf.set_text_color(255, 255, 255)
    pdf.set_x(MARGIN)
    pdf.multi_cell(WIDTH, 14, data["cover_title"], align="C")
    pdf.set_x(MARGIN)
    pdf.set_font("Arial", "", 18)
    pdf.multi_cell(WIDTH, 10, data["cover_subtitle"], align="C")

    pdf.set_y(96)
    pdf.set_text_color(40, 40, 40)
    pdf.set_font("Arial", "B", 15)
    pdf.set_x(MARGIN)
    pdf.multi_cell(WIDTH, 9, data["summary_title"])
    pdf.ln(3)
    pdf.set_font("Arial", "", 13)
    pdf.set_x(MARGIN)
    pdf.multi_cell(WIDTH, 7.5, data["summary"])

    pdf.ln(6)
    pdf.set_font("Arial", "B", 14)
    pdf.set_text_color(30, 64, 115)
    pdf.set_x(MARGIN)
    pdf.multi_cell(WIDTH, 9, data["tech_title"])
    pdf.ln(2)
    pdf.set_text_color(40, 40, 40)
    for item in data["tech_items"]:
        pdf.bullet(item)

    # --- Gereksinimler ---
    pdf.add_page()
    pdf.page_heading(data["req_title"])

    for i, (title, items) in enumerate(data["sections"], 1):
        pdf.section_title(i, title)
        for item in items:
            pdf.bullet(item)
        pdf.ln(2)

    # --- Degerlendirme + Bonus ---
    pdf.add_page()
    pdf.page_heading(data["eval_title"])

    for title, desc in data["criteria"]:
        pdf.set_font("Arial", "B", 13)
        pdf.set_text_color(30, 64, 115)
        pdf.set_x(MARGIN)
        pdf.multi_cell(WIDTH, 8, title)
        pdf.set_font("Arial", "", 12.5)
        pdf.set_text_color(40, 40, 40)
        pdf.set_x(MARGIN)
        pdf.multi_cell(WIDTH, 7, desc)
        pdf.ln(3)

    pdf.ln(4)
    pdf.set_font("Arial", "B", 16)
    pdf.set_text_color(30, 64, 115)
    pdf.set_x(MARGIN)
    pdf.multi_cell(WIDTH, 9, data["bonus_title"])
    pdf.ln(3)

    for i, q in enumerate(data["bonus"], 1):
        pdf.set_font("Arial", "B", 12.5)
        pdf.set_text_color(30, 64, 115)
        pdf.set_x(MARGIN)
        pdf.cell(10, 7, f"{i}.")
        pdf.set_font("Arial", "", 12.5)
        pdf.set_text_color(40, 40, 40)
        pdf.multi_cell(WIDTH - 10, 7, q)
        pdf.ln(2)

    out = README_DIR / data["file"]
    pdf.output(str(out))
    return out


if __name__ == "__main__":
    for language in ("en", "tr"):
        print(build(language))
