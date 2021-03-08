from selenium import webdriver
from selenium.webdriver.firefox import options
from selenium.common.exceptions import WebDriverException
from selenium.common.exceptions import NoSuchElementException
from bs4 import BeautifulSoup
import time
import os
import psutil
from .constants import (
    ARCHIVED_BREACHES_LINK,
    CSV_BUTTON,
    HHS_URL,
)


class Robot:

    archive_dir = "archive"
    cur_cases_dir = "currently_under_investigation"
    csv_name = "breach_report.csv"

    # need to clean data_downloads directory or inserted files
    # will clash with old ones

    def __init__(
        self, headless_browser: bool = False, download_dir: str = "data_downloads"
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

    def click_button(self, xpath: str) -> bool:
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

    def get_research_report_xpath(self) -> str:
        if len(self.driver.page_source) < 45:
            self.driver.get(HHS_URL)
            time.sleep(5)
            self.click_button(ARCHIVED_BREACHES_LINK)
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

    def get_current_open_breaches(self, keep_open: bool = False) -> bool:
        self.driver.get(HHS_URL)
        time.sleep(2)
        if not self.click_button(CSV_BUTTON):
            try:
                self.click_button(self._get_csv_xpath())
            except NoSuchElementException as e:
                print("NoSuchElementException. " "CSV button not found", e)
        print("just clicked csv button")
        if not keep_open:
            return self._full_driver_quit(archive=False)
        if not self._file_is_downloaded():
            return False
        self._move_to_subdirectory(archive=False)
        self._clean_download_dir()
        self._kill_zombies()
        return True

    def get_archived_breaches(self) -> bool:
        """

        Parameters
        ----------

        Returns
        -------

        """
        if len(self.driver.page_source) < 45:
            self.driver.get(HHS_URL)
            time.sleep(5)
        self.click_button(ARCHIVED_BREACHES_LINK)
        print("just clicked archive button")
        self.click_button(self.get_research_report_xpath())
        print("just clicked research report button")
        time.sleep(5)
        if not self.click_button(CSV_BUTTON):
            self.click_button(self._get_csv_xpath())
        print("just clicked csv button for research report")
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
        self._move_to_subdirectory(archive=archive)
        self._clean_download_dir()
        return True

    def _move_to_subdirectory(self, archive: bool = True) -> bool:
        """
        Move new csv download from ~/download_dir to either
        ~/download_dir/archive or
        ~/download_dir/currently_under_investigation
        Parameters
        ----------
        archive: bool
            Whether subdirectory to place new csv in is archived
            breaches or not
        Returns
        -------
        """
        if not archive:
            new_parent_dir = self.cur_cases_dir
        else:
            new_parent_dir = self.archive_dir
        sep = os.path.sep
        new_parent_dir = sep.join([self.download_dir, new_parent_dir])
        if not os.path.exists(new_parent_dir):
            os.mkdir(new_parent_dir)
        try:
            old_name = sep.join([self.download_dir, self.csv_name])
            new_name = sep.join([new_parent_dir, self.csv_name])
            os.rename(old_name, new_name)
        except FileNotFoundError as e:
            print(e)

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
        _file_is_downloaded() and get_archived_breaches() work as
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
        after calling get_archived_breaches() or
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


if __name__ == "__main__":
    Robot()
