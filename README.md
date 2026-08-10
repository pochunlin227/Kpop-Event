# 💎 SVT 生咖雷達

SEVENTEEN 生日咖啡廳應援活動追蹤 App(iOS / Android / Web)。

- 自動爬取台灣、韓國、美國、新加坡的生咖/cupsleeve 活動
- 成員生日倒數、地區與成員篩選、歷史活動年份回顧
- 資料來源:STELLAR 台灣生咖地圖、Yahoo 搜尋(Threads 貼文)、Google News、Accupass 等

## 開發

```bash
flutter run -d web-server --web-port=8788   # Web 開發
python3 crawler/crawl.py                     # 手動執行爬蟲
```

## 部署

推上 GitHub 後,`.github/workflows/deploy.yml` 會:
1. 每天台北時間 10:00 自動爬新活動並 commit
2. 自動建置並部署到 GitHub Pages

成員頭像出處見 [ATTRIBUTIONS.md](ATTRIBUTIONS.md)。
