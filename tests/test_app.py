import time
import requests
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.options import Options

BASE_URL = "http://127.0.0.1:5000"

def wait_for_app(timeout=15):
    start = time.time()
    while time.time() - start < timeout:
        try:
            r = requests.get(f"{BASE_URL}/health", timeout=2)
            if r.status_code == 200:
                return True
        except Exception:
            pass
        time.sleep(0.5)
    raise RuntimeError("App did not start in time")

def make_driver():
    options = Options()
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    service = ChromeService(ChromeDriverManager().install())
    return webdriver.Chrome(service=service, options=options)

def test_home_button_click():
    assert wait_for_app()
    driver = make_driver()
    try:
        driver.get(BASE_URL + "/")
        btn = driver.find_element("id", "btn")
        btn.click()
        out = driver.find_element("id", "out")
        assert out.text == "clicked"
    finally:
        driver.quit()
