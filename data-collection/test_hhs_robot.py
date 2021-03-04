
import pytest
import os
# test coverage
from hhs_robot import Robot

@pytest.fixture # Arrange
def robot():
    return Robot()

@pytest.fixture
def directory():
    return os.path.abspath('data_downloads')

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

def test_csvs_download_to_specced_dir(robot: Robot, directory: str, csv_name: str):
    robot.get_archived_breaches()
    assert csv_name in os.listdir(directory)

# close 

