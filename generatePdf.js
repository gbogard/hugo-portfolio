const { resolve } = require("path")
const { chromium } = require("playwright")

const out = resolve(__dirname, "assets", "./resume.pdf");

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage()
  await page.goto("http://localhost:1313/resume/")
  await page.pdf({
    path: out,
    preferCSSPageSize: true,
    printBackground: true,
    margin: {
      top: 100
    }
  })
  await browser.close();
})()
