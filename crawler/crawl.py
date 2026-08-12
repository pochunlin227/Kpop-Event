#!/usr/bin/env python3
"""SEVENTEEN 生日咖啡廳爬蟲

搜尋 DuckDuckGo(含 Threads 貼文)與 Google News,找出新的生日應援咖啡廳活動,
合併寫入 data/events.json (App 會讀取這份資料)。

用法:
    python3 crawler/crawl.py            # 爬取並合併新活動
    python3 crawler/crawl.py --dry-run  # 只顯示找到什麼,不寫檔
"""
import html as html_mod
import json
import re
import sys
import unicodedata
import time
import hashlib
import urllib.parse
import urllib.request
from html.parser import HTMLParser
from pathlib import Path
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parent.parent
EVENTS_FILE = ROOT / "data" / "events.json"

UA = ("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) "
      "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36")

MEMBERS = [
    {"id": "scoups",    "birthday": (8, 8),   "names": ["S.Coups", "SCoups", "에스쿱스", "쿱스", "승철", "崔勝澈", "勝澈"]},
    {"id": "jeonghan",  "birthday": (10, 4),  "names": ["Jeonghan", "정한", "尹淨漢", "淨漢"]},
    {"id": "joshua",    "birthday": (12, 30), "names": ["Joshua", "조슈아", "지수", "洪知秀", "知秀"]},
    {"id": "jun",       "birthday": (6, 10),  "names": ["Jun", "준", "문준휘", "文俊輝", "俊輝"]},
    {"id": "hoshi",     "birthday": (6, 15),  "names": ["Hoshi", "호시", "순영", "權順榮", "順榮"]},
    {"id": "wonwoo",    "birthday": (7, 17),  "names": ["Wonwoo", "원우", "全圓佑", "圓佑"]},
    {"id": "woozi",     "birthday": (11, 22), "names": ["Woozi", "우지", "지훈", "李知勳", "知勳"]},
    {"id": "dk",        "birthday": (2, 18),  "names": ["DK", "도겸", "석민", "李碩珉", "碩珉"]},
    {"id": "mingyu",    "birthday": (4, 6),   "names": ["Mingyu", "민규", "金珉奎", "珉奎"]},
    {"id": "the8",      "birthday": (11, 7),  "names": ["The8", "디에잇", "명호", "徐明浩", "明浩", "小八"]},
    {"id": "seungkwan", "birthday": (1, 16),  "names": ["Seungkwan", "승관", "夫勝寬", "勝寬"]},
    {"id": "vernon",    "birthday": (2, 18),  "names": ["Vernon", "버논", "한솔", "崔韓率", "韓率"]},
    {"id": "dino",      "birthday": (2, 11),  "names": ["Dino", "디노", "이찬", "李燦", "燦"]},
]

# 生咖相關關鍵字(中/韓/英)
CAFE_KEYWORDS = ["生日咖啡廳", "生日應援", "生咖", "생일카페", "생카", "컵홀더",
                 "杯套", "應援咖啡", "cup holder", "birthday cafe", "생일 카페",
                 "cupsleeve", "cup sleeve", "birthday event", "bday cafe"]

# 基本搜尋查詢組合(台灣/韓國/美國/新加坡)
QUERIES = [
    "SEVENTEEN 生日咖啡廳",
    "SEVENTEEN 生咖 杯套",
    "세븐틴 생일카페",
    "SEVENTEEN 生日應援 site:threads.net",
    "세븐틴 생카 site:threads.net",
    "SEVENTEEN 컵홀더 이벤트",
    "SEVENTEEN birthday cafe cupsleeve",
    "SEVENTEEN cupsleeve event Singapore",
    "SEVENTEEN cupsleeve event USA",
    "SEVENTEEN birthday cup sleeve site:threads.net",
]


def birthday_boost_queries(today=None):
    """生日前 45 天到後 14 天的成員,加強針對性搜尋(站姐通常提前 1-2 個月公告)"""
    from datetime import date, timedelta
    today = today or date.today()
    queries = []
    for m in MEMBERS:
        month, day = m["birthday"]
        bday = date(today.year, month, day)
        for candidate in (bday, bday.replace(year=today.year + 1),
                          bday.replace(year=today.year - 1)):
            delta = (candidate - today).days
            if -14 <= delta <= 45:
                zh, ko = m["names"][-1], m["names"][1]
                en = m["names"][0]
                queries += [
                    f"{en} 生日應援 生咖",
                    f"{zh}生咖",          # Threads hashtag 慣用寫法
                    f"{zh} 生日咖啡廳 台北",
                    f"{ko}생카",
                    f"{en} 生咖 site:threads.net",
                    f"SEVENTEEN {en} birthday cafe cupsleeve",
                    f"SEVENTEEN {en} cupsleeve Singapore",
                ]
                break
    return queries

# 各地區關鍵字線索(依序比對,先中就是該地區)
REGION_HINTS = {
    "TW": ["台北", "臺北", "台中", "臺中", "台南", "臺南", "高雄", "新竹", "桃園",
           "南投", "台灣", "臺灣", "西門", "東區", "板橋", "taipei", "taiwan"],
    "KR": ["서울", "홍대", "합정", "강남", "성수", "건대", "부산", "대구",
           "韓國", "首爾", "弘大", "聖水", "seoul", "hongdae", "korea"],
    "US": ["usa", "united states", "los angeles", " nyc", "new york", "chicago",
           "houston", "san francisco", "seattle", "dallas", "atlanta", "texas",
           "california", "美國", "洛杉磯", "紐約"],
    "SG": ["singapore", "新加坡", "싱가포르", "bugis", "orchard", "tampines",
           "bras basah"],
}

# 購物/二手/舊文等雜訊來源
DOMAIN_BLOCKLIST = ["shopee.tw", "coupang", "ruten.com", "carousell",
                    "dcard.tw", "pinterest.", "youtube.com",
                    "etsy.com", "bunjang", "ebay.", "amazon.",
                    # 廣告轉址(真實網址被編碼藏在參數裡,擋掉整類)
                    "bing.com/aclick", "duckduckgo.com/y.js",
                    "googleadservices", "doubleclick", "onelink.me"]

# 標題含購物廣告用語的直接跳過
NOISE_TITLE_WORDS = ["特價", "購物網", "免運", "優惠碼", "折扣碼", "今日下殺", "拍賣"]


def fetch(url: str) -> str:
    # 用系統 curl 抓取,避免 Python 憑證環境問題
    import subprocess
    out = subprocess.run(
        ["curl", "-s", "--max-time", "20", "-A", UA,
         "-H", "Accept-Language: zh-TW,zh;q=0.9,ko;q=0.8", url],
        capture_output=True, check=True)
    return out.stdout.decode("utf-8", errors="replace")


class DDGParser(HTMLParser):
    """解析 DuckDuckGo HTML 版搜尋結果"""
    def __init__(self):
        super().__init__()
        self.results = []
        self._in_link = False
        self._href = None
        self._text = []

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "a" and "result__a" in (a.get("class") or ""):
            self._in_link = True
            self._href = a.get("href", "")
            self._text = []

    def handle_data(self, data):
        if self._in_link:
            self._text.append(data)

    def handle_endtag(self, tag):
        if tag == "a" and self._in_link:
            self._in_link = False
            url = self._href
            # DuckDuckGo 轉址連結 → 還原真實網址
            m = re.search(r"uddg=([^&]+)", url)
            if m:
                url = urllib.parse.unquote(m.group(1))
            self.results.append({"title": "".join(self._text).strip(), "url": url})


def search_ddg(query: str):
    url = "https://html.duckduckgo.com/html/?q=" + urllib.parse.quote(query)
    try:
        parser = DDGParser()
        parser.feed(fetch(url))
        return parser.results
    except Exception as e:
        print(f"  [警告] DuckDuckGo 查詢失敗 ({query}): {e}", file=sys.stderr)
        return []


def search_yahoo(query: str):
    """Yahoo 台灣搜尋:對爬蟲較友善,且會收錄 Threads 貼文/標籤頁"""
    url = "https://tw.search.yahoo.com/search?p=" + urllib.parse.quote(query)
    try:
        html = fetch(url)
        results = []
        # 組織結果藏在 r.search.yahoo.com 轉址的 RU= 參數;標題在同一個 <a> 內
        for m in re.finditer(
                r'href="https://r\.search\.yahoo\.com/[^"]*?RU=([^/"]+)/[^"]*"[^>]*>(.*?)</a>',
                html, re.S):
            real = urllib.parse.unquote(m.group(1))
            # 去掉 <span class="s-url">(網址麵包屑)再抽純文字標題
            inner = re.sub(r"<span[^>]*s-url.*?</span>", "", m.group(2), flags=re.S)
            title = re.sub(r"<[^>]+>", "", inner).strip()
            if not real.startswith("http") or "yahoo.com" in real:
                continue
            if "threads.com/login" in real or "/settings/" in real or real.rstrip("/").endswith(("threads.com", "threads.net")):
                continue
            results.append({"title": title, "url": real})
        return results
    except Exception as e:
        print(f"  [警告] Yahoo 查詢失敗 ({query}): {e}", file=sys.stderr)
        return []


def search_google_news(query: str):
    url = ("https://news.google.com/rss/search?q=" + urllib.parse.quote(query)
           + "&hl=zh-TW&gl=TW&ceid=TW:zh-Hant")
    try:
        xml = fetch(url)
        items = re.findall(r"<item>(.*?)</item>", xml, re.S)
        results = []
        for item in items:
            t = re.search(r"<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>", item, re.S)
            l = re.search(r"<link>(.*?)</link>", item, re.S)
            if t and l:
                results.append({"title": t.group(1).strip(), "url": l.group(1).strip()})
        return results
    except Exception as e:
        print(f"  [警告] Google News 查詢失敗 ({query}): {e}", file=sys.stderr)
        return []


def import_stellar(member_id: str, known_urls):
    """STELLAR 台灣生咖地圖 (stellar-zone.com):結構化活動列表,含日期/城市/店名"""
    url = f"https://www.stellar-zone.com/map/{member_id}"
    try:
        page = fetch(url)
    except Exception as e:
        print(f"  [警告] STELLAR 地圖抓取失敗 ({member_id}): {e}", file=sys.stderr)
        return []
    events = []
    for m in re.finditer(r'href="(/event/[^"]+)"[^>]*>(.*?)</a>', page, re.S):
        link = "https://www.stellar-zone.com" + m.group(1)
        if link in known_urls:
            continue
        text = html_mod.unescape(re.sub(r"<[^>]+>", " ", m.group(2)))
        text = re.sub(r"\s+", " ", text).strip()
        dm = re.search(r"(\d{4})/(\d{1,2})/(\d{1,2})\s*-\s*(\d{4})/(\d{1,2})/(\d{1,2})", text)
        if not dm:
            continue
        y1, mo1, d1, y2, mo2, d2 = (int(x) for x in dm.groups())
        cm = re.match(r"^(\S+?[市縣])\s*(.*)$", text[:dm.start()].strip())
        city = cm.group(1) if cm else None
        title = clean_title(cm.group(2) if cm else text[:dm.start()])
        venue = text[dm.end():].strip()[:40] or None
        if any(e["sourceUrl"] == link for e in events):
            continue
        events.append({
            "id": hashlib.sha1(link.encode()).hexdigest()[:12],
            "title": title or f"{member_id} 生日應援",
            "member": member_id,
            "region": "TW",
            "status": "confirmed",
            "eventStart": f"{y1:04d}-{mo1:02d}-{d1:02d}",
            "eventEnd": f"{y2:04d}-{mo2:02d}-{d2:02d}",
            "signupStart": None,
            "signupEnd": None,
            "location": " · ".join(x for x in (city, venue) if x),
            "sourceUrl": link,
            "source": "stellar",
            "foundAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        })
        known_urls.add(link)
    return events


def guess_member(text: str):
    for m in MEMBERS:
        for name in m["names"]:
            if name.lower() in text.lower():
                return m["id"]
    return None


def guess_region(text: str):
    low = text.lower()
    for region, hints in REGION_HINTS.items():
        if any(h.lower() in low for h in hints):
            return region
    if re.search(r"[가-힣]", text):
        return "KR"
    if re.search(r"[一-鿿]", text):
        return "TW"
    return None


def clean_title(s: str) -> str:
    """花體字轉一般字母(NFKC),去掉字型無法顯示的 emoji/裝飾符號"""
    s = unicodedata.normalize("NFKC", html_mod.unescape(s))
    out = []
    for ch in s:
        cp = ord(ch)
        if cp >= 0x1F000 or 0x2600 <= cp <= 0x27BF or 0xFE00 <= cp <= 0xFE0F:
            continue  # emoji 與變體選擇符
        out.append(ch)
    return re.sub(r"\s+", " ", "".join(out)).strip(" -|·,")


MONTHS = {m: i + 1 for i, m in enumerate(
    ["january", "february", "march", "april", "may", "june", "july",
     "august", "september", "october", "november", "december"])}


def parse_english_date(text: str):
    """從標題解析英文日期,如 'Los Angeles, May 30, 2026' → 2026-05-30"""
    m = re.search(r"\b(" + "|".join(MONTHS) + r")\s+(\d{1,2}),?\s+(\d{4})",
                  text, re.I)
    if not m:
        return None
    return f"{int(m.group(3)):04d}-{MONTHS[m.group(1).lower()]:02d}-{int(m.group(2)):02d}"


def is_cafe_related(text: str) -> bool:
    return any(k.lower() in text.lower() for k in CAFE_KEYWORDS)


def source_of(url: str) -> str:
    if "threads.net" in url or "threads.com" in url:
        return "threads"
    if "instagram.com" in url:
        return "instagram"
    if "stellar-zone.com" in url:
        return "stellar"
    if "accupass.com" in url:
        return "accupass"
    if "news.google" in url:
        return "news"
    return "web"


def enrich_accupass(events) -> bool:
    """Accupass 報名頁有結構化資料(ld+json),自動補日期/地點"""
    changed = False
    for e in events:
        if e.get("source") != "accupass" or e.get("eventStart"):
            continue
        try:
            page = fetch(e["sourceUrl"])
        except Exception:
            continue
        for m in re.finditer(r'<script type="application/ld\+json">(.*?)</script>', page, re.S):
            try:
                d = json.loads(m.group(1))
            except ValueError:
                continue
            if isinstance(d, dict) and d.get("@type") == "Event":
                e["eventStart"] = (d.get("startDate") or "")[:10] or None
                e["eventEnd"] = (d.get("endDate") or "")[:10] or None
                loc = d.get("location") or {}
                addr = loc.get("address")
                if isinstance(addr, dict):
                    addr = addr.get("streetAddress")
                e["location"] = " · ".join(x for x in (loc.get("name"), addr) if x) or None
                e["status"] = "confirmed"
                if not e.get("region") and addr:
                    e["region"] = guess_region(addr)
                changed = True
                break
    return changed


def main():
    dry_run = "--dry-run" in sys.argv

    existing = {"events": []}
    if EVENTS_FILE.exists():
        existing = json.loads(EVENTS_FILE.read_text(encoding="utf-8"))
    known_urls = {e.get("sourceUrl") for e in existing["events"]}

    # 自訂查詢: python3 crawl.py --query "勝澈 生咖 台北"
    extra = [a for a in sys.argv[1:] if not a.startswith("--")]
    boost = birthday_boost_queries()
    if boost:
        print(f"生日加強搜尋: {len(boost)} 組查詢")
    all_queries = QUERIES + boost + extra

    found = []
    # 先匯入 STELLAR 台灣生咖地圖(結構化資料,直接標為 confirmed)
    print("匯入 STELLAR 台灣生咖地圖...")
    for m in MEMBERS:
        stellar = import_stellar(m["id"], known_urls)
        if stellar:
            print(f"  {m['id']}: {len(stellar)} 筆活動")
        found.extend(stellar)
        time.sleep(1)

    for q in all_queries:
        print(f"搜尋: {q}")
        results = search_ddg(q) + search_yahoo(q) + search_google_news(q)
        for r in results:
            title, url = clean_title(r["title"]), r["url"]
            if not title or not url or url in known_urls:
                continue
            if any(d in url for d in DOMAIN_BLOCKLIST):
                continue
            if any(w in title for w in NOISE_TITLE_WORDS):
                continue
            # 標題只是網址/網域的沒資訊量,跳過
            if re.fullmatch(r"(https?://)?[\w.\-]+(\.\w{2,})(/\S*)?", title):
                continue
            # 過期年份的舊文跳過
            years = [int(y) for y in re.findall(r"\b(20\d{2})\b", title)]
            if years and max(years) < datetime.now().year:
                continue
            # 標籤頁的資訊藏在網址裡,一併納入判斷
            text = title + " " + urllib.parse.unquote(url)
            # 要含生咖關鍵字;Threads 貼文標題常被截斷,放寬為含成員名或 SEVENTEEN
            from_threads = source_of(url) == "threads"
            if not is_cafe_related(text) and not (
                    from_threads and ("seventeen" in text.lower() or "세븐틴" in text or guess_member(text))):
                continue
            eid = hashlib.sha1(url.encode()).hexdigest()[:12]
            if any(f["id"] == eid for f in found):
                continue
            eng_date = parse_english_date(title)
            found.append({
                "id": eid,
                "title": title,
                "member": guess_member(text),
                "region": guess_region(title),
                "status": "candidate",          # 候選:待人工確認日期
                "eventStart": eng_date,
                "eventEnd": eng_date,
                "signupStart": None,
                "signupEnd": None,
                "location": None,
                "sourceUrl": url,
                "source": source_of(url),
                "foundAt": datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
            })
            known_urls.add(url)
        time.sleep(8)  # 禮貌性間隔,DuckDuckGo 連續查詢會被暫時擋下

    print(f"\n共找到 {len(found)} 筆新候選活動")
    for f in found:
        print(f"  [{f['member'] or '?'}] {f['title'][:60]}  ({f['source']})")

    if dry_run:
        return

    existing["events"].extend(found)
    enrich_accupass(existing["events"])
    # 沒有新資料也更新時間戳:App 顯示的「資料更新」代表上次檢查時間,
    # 讓使用者能確認排程有在跑
    existing["updatedAt"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    EVENTS_FILE.parent.mkdir(parents=True, exist_ok=True)
    EVENTS_FILE.write_text(json.dumps(existing, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"已寫入 {EVENTS_FILE}")


if __name__ == "__main__":
    main()
