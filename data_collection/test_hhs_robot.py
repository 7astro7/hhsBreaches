
import pytest
from .hhs_robot import Bot

# test zombie processes

@pytest.fixture # Arrange
def robot():
    return Bot()

def test_get_all_breaches_method_works(
        robot: Bot,
        ): 
    assert robot.get_all_breaches() == True

