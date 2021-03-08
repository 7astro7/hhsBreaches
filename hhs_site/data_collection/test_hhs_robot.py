
import pytest
import os
# test coverage
from hhs_robot import Robot
from constants import CUR_BREACHES_TITLE

# test zombie processes

@pytest.fixture # Arrange
def robot():
    return Robot()

@pytest.fixture
def csv_name():
    return 'breach_report.csv'

@pytest.mark.skip(reason = '')
def test_click_button(robot):
    pass

@pytest.mark.skip(reason = '')
def test_click_button_raises(robot):
    pass

@pytest.mark.skip(reason = '')
def test_get_research_report_xpath(robot):
    # 
    pass

@pytest.mark.skip(reason = '')
def test_get_csv_xpath(robot):
    pass

@pytest.mark.skip(reason = '')
def test_get_current_open_breaches(robot):
    pass

@pytest.mark.skip(reason = '')
def test_get_archived_breaches(robot):
    pass

@pytest.mark.skip(reason = '')
def test_csvs_download_sans_popup(robot: Robot):
    pass

def test_csvs_download_to_specced_dir(robot: Robot, csv_name: str):
    robot.get_archived_breaches()
    dir_contents = ''.join(os.listdir(robot.download_dir))
    is_downloaded = csv_name in dir_contents
    no_partial_downloads = 'part' not in dir_contents
    assert is_downloaded and no_partial_downloads

# close 

