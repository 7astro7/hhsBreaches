
from selenium import webdriver 
from selenium.webdriver.firefox import options
from selenium.common.exceptions import WebDriverException, NoSuchElementException
from bs4 import BeautifulSoup
import time
import os

# current cases under investigation / home page
HHS_URL = 'https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf'

xpath_map = {
    # path to archived cases: cases not under investigation
    'archived_breaches_link': 
        '/html/body/div[2]/div[2]/div/div[2]/form/div[1]/div/button[2]/span',
    # research report csv xpath: case is in archive research report csv if: 
    #   case age > 24 months or case is resolved
    'csv_button': '//*[@id="ocrForm:j_idt365"]'
}

class Robot:
    
    def __init__(self, headless: bool = False, 
            download_dir: str = 'data_downloads'):
        self.options = options.Options()
        self.options.set_preference(
            'browser.helperApps.neverAsk.saveToDisk', 'text/csv')
        self.headless = headless
        if self.headless:
            self.options.headless = True
        if not os.path.exists(download_dir):
            os.mkdir(self.download_dir)
        self.download_dir = os.path.abspath(download_dir)
        # don't use default Downloads directory
        self.options.set_preference('browser.download.folderList', 2)
        # set download directory
        self.options.set_preference('browser.download.dir', self.download_dir)
        self.driver = webdriver.Firefox(options = self.options)
        if self.driver is not None:
            self.driver.implicitly_wait(12)
            self.driver.set_page_load_timeout(30)

    def click_button(self, xpath: str) -> bool:
        #if self.driver is None:
        try:
            button = self.driver.find_element_by_xpath(xpath)
        except NoSuchElementException as e:
            print('NoSuchElement exception. ', e)
            return False
        time.sleep(5)
        button.click()
        return True

    def get_research_report_xpath(self):
        if len(self.driver.page_source) < 45:
            self.driver.get(HHS_URL)
            time.sleep(5)
            self.click_button(xpath_map['archived_breaches_link'])
        soup = BeautifulSoup(self.driver.page_source, 
                             features = 'html.parser')
        a_tags = soup.findAll('a')
        for i in range(len(a_tags)):
            tag_text = a_tags[i].text.lower().replace(' ', '_') 
            if ('research' in tag_text or 'report' in tag_text):
                return '//*[@id="{}"]'.format(a_tags[i].attrs['id'])

    def get_csv_xpath(self):
        if len(self.driver.page_source) < 45:
            self.driver.get(HHS_URL)
            time.sleep(5)
        soup = BeautifulSoup(self.driver.page_source, 
                             features = 'html.parser')
        a_tags = soup.findAll('img')
        for i in range(len(a_tags)):
            if 'title' in a_tags[i].attrs.keys():
                if 'csv' in a_tags[i].attrs['title'].lower():
                    return '//*[@id="{}"]'.format(a_tags[i].attrs['id'])

    def get_current_open_breaches(self):
        self.driver.get(HHS_URL)
        time.sleep(2)
        self.click_button(self.get_csv_xpath())
        print('just clicked csv button')
    
    def get_archived_breaches(self):
        if len(self.driver.page_source) < 45:
            self.driver.get(HHS_URL)
            time.sleep(5)
        self.click_button(xpath_map['archived_breaches_link']) 
        print('just clicked archive button')
        self.click_button(self.get_research_report_xpath())
        print('just clicked research report button')
        time.sleep(5)
        if not self.click_button(self.get_csv_xpath()):
            self.click_button(xpath_map['csv_button'])
        time.sleep(5) # closing driver too soon can stop downloads
        print('just clicked csv button for research report. Closing')
        self.driver.close()
        

if __name__ == "__main__":
    Robot()
