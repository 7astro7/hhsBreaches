
import os

# current cases under investigation / home page
HHS_URL = 'https://ocrportal.hhs.gov/ocr/breach/breach_report.jsf'

CUR_BREACHES_TITLE = 'Cases Currently Under Investigation'.lower()
CUR_BREACHES_TITLE = set(CUR_BREACHES_TITLE.split())
CUR_BREACHES_SUBTITLE = 'This page lists all breaches reported' \
        'within the last 24 months that are currently under' \
        'investigation by the Office for Civil Rights.'
CUR_BREACHES_SUBTITLE = set(CUR_BREACHES_SUBTITLE.lower().split())

# path to archived cases: cases not under investigation
ARCHIVED_BREACHES_LINK = '/html/body/div[2]/div[2]/div/div[2]/'\
                    'form/div[1]/div/button[2]/span'

# research report csv xpath: case is in archive research report csv if: 
#   case age > 24 months or case is resolved
CSV_BUTTON = '//*[@id="ocrForm:j_idt365"]'
# text for xpath should say 'Cases Currently Under Investigation'
CUR_BREACHES_TITLE = '/html/body/div[2]/div[2]/div/div[2]/form/'\
                    'span[1]/span/table/tbody/tr[1]/td/span'
# text for xpath should say 'this page lists all breaches reported within the last
# 24 months that are currently under investigation by the office for civil rights'
CUR_BREACHES_SUBTITLE = '/html/body/div[2]/div[2]/div/div[2]/form'\
                        '/span[1]/span/table/tbody/tr[2]/td'