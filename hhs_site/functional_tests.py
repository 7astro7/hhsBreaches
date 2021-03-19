
from selenium import webdriver
import pytest

# reference pytest philosophy
# may make sense to add setup and tear down to a utils module

@pytest.fixture
def set_up():
    return webdriver.Firefox()

@pytest.fixture
def tear_down():
    # quit browser
    pass

# rough draft

def test_breaches_descending_inds_affected_shown(set_up):
    """
    Betty wants to see if her impression that her private medical 
    data is immune from being hacked aligns with the empirical 
    distribution of individuals affected among hhs breaches: 
    she visits map breaches to test her bias
    """
    # browser.get('http:localhost:8000')
    # assert breaches shown in descending order
    pass

def test_map_shown_scaled_by_total_inds_affected():
    """
    serve map scaled proportionate to total number of inds affected
    i.e., bigger state in plot for greater (absolute) number of inds affected
    """
    pass

def test_map_shown_scaled_by_total_inds_affected_per_capita():
    """
    serve map scaled proportionate to total number of inds affected
    per 1k citizens of state
    """
    pass

def test_map_shown_scaled_by_total_inds_affected_per_capita():
    """
    serve map scaled proportionate to total number of inds affected
    per 1k citizens of state
    """
    pass
    



