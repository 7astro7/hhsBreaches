from selenium import webdriver
from selenium.webdriver.firefox import options
from selenium.common.exceptions import WebDriverException
from selenium.common.exceptions import NoSuchElementException
from bs4 import BeautifulSoup
import time
import os
import psutil
from data_collection.constants import (
    ARCHIVED_BREACHES_LINK,
    CSV_BUTTON,
    HHS_URL,
)


class Bot:
    """
    a selenium bot created to download all HHS archive data, see
    https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf
    """

    def __init__(
        self, 
        headless_browser: bool = True, 
        download_dir: str = "data",
    ):
        self.options = options.Options()
        self.options.set_preference(
            "browser.helperApps.neverAsk.saveToDisk", "text/csv"
        )
        self.headless_browser = headless_browser
        if self.headless_browser:
            self.options.headless = True
        if not os.path.exists(download_dir):
            os.mkdir(download_dir)
        self.download_dir = os.path.abspath(download_dir)
        # don't use default Downloads directory
        self.options.set_preference("browser.download.folderList", 2)
        # set download directory
        self.options.set_preference("browser.download.dir", self.download_dir)
        self.driver = webdriver.Firefox(options=self.options)
        if self.driver is not None:
            self.driver.implicitly_wait(12)
            self.driver.set_page_load_timeout(30)

    def __str__(self):
        return self.driver.__str__()

    def _click_button(self, xpath: str) -> bool:
        if len(self.driver.page_source) < 45:
            return False
        try:
            button = self.driver.find_element_by_xpath(xpath)
        except NoSuchElementException as e:
            print("NoSuchElement exception. ", e)
            return False
        time.sleep(5)
        button.click()
        self._kill_zombies()
        return True

    def _get_research_report_xpath(self) -> str:
        if len(self.driver.page_source) < 45:
            self.driver.get(HHS_URL)
            time.sleep(5)
            self._click_button(ARCHIVED_BREACHES_LINK)
        soup = BeautifulSoup(self.driver.page_source, features="html.parser")
        a_tags = soup.findAll("a")
        for i in range(len(a_tags)):
            tag_text = a_tags[i].text.lower().replace(" ", "_")
            if "research" in tag_text or "report" in tag_text:
                return '//*[@id="{}"]'.format(a_tags[i].attrs["id"])

    def _get_csv_xpath(self) -> str:
        if len(self.driver.page_source) < 45:
            self.driver.get(HHS_URL)
            time.sleep(5)
        soup = BeautifulSoup(self.driver.page_source, features="html.parser")
        a_tags = soup.findAll("img")
        for i in range(len(a_tags)):
            if "title" in a_tags[i].attrs.keys():
                if "csv" in a_tags[i].attrs["title"].lower():
                    id_key = a_tags[i].attrs["id"]
                    return '//*[@id="{}"]'.format(id_key)

    def get_all_breaches(self) -> bool:
        """

        Parameters
        ----------
        None

        Returns
        -------

        """
        if len(self.driver.page_source) < 45:
            self.driver.get(HHS_URL)
            time.sleep(5)
        self._click_button(ARCHIVED_BREACHES_LINK)
        self._click_button(self._get_research_report_xpath())
        time.sleep(5)
        if not self._click_button(CSV_BUTTON):
            self._click_button(self._get_csv_xpath())
        time.sleep(2)
        return self._full_driver_quit()

    def _full_driver_quit(self, archive: bool = True):
        """"""
        download_worked = self._file_is_downloaded()
        self.driver.quit()
        self._kill_zombies()
        if not download_worked:
            self._clean_download_dir()
            return False
        self._clean_download_dir()
        return True

    def _kill_zombies(self):
        """Kill non-ephemeral zombie processes to minimize resource
        leaks and ensure browser processes that haven't been properly
        quit are terminated as soon as possible

        Parameters
        ----------

        Returns
        -------
        """
        processes = tuple(psutil.process_iter())
        exists = lambda ps: ps.is_running()
        is_undead = lambda ps: ps.status() == "zombie"
        running = tuple(filter(exists, processes))
        zombies = tuple(filter(is_undead, running))
        for zombie in zombies:
            zombie.kill()

    def _clean_download_dir(self):
        """Remove any file in self.download_dir that has 'part' in
        its name. 'part' denotes the file is partially downloaded:
        removing such files helps ensure methods
        _file_is_downloaded() and get_all_breaches_breaches() work as
        expected."""
        download_dir_contents = os.listdir(self.download_dir)
        i = 0
        while True:
            if i >= len(download_dir_contents):
                break
            a_file_name = download_dir_contents[i].lower()
            if "part" in a_file_name:
                path_to_file = os.path.abspath(a_file_name)
                os.remove(path_to_file)
            i += 1

    def _file_is_downloaded(self) -> bool:
        """
        Indicate if file is downloaded to self.download_dir
        after calling get_all_breaches_breaches() or
        get_current_open_breaches(): closing driver too soon can
        stop downloads

        Parameters
        ----------
        None

        Returns
        -------
        bool: True if no file in self.download_dir has substring
              'part' in it that denotes only partial download has
              occured.
              False if a minute has passed since invocation of
              function, 'part' is still found in the name of at
              least one file in self.download_dir
        """
        start_time = time.time()
        while "part" in " ".join(os.listdir(self.download_dir)):
            time.sleep(20)
            if time.time() - start_time >= 60:
                return False
        return True

