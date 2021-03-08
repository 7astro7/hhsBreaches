
import datetime
from django.db.models import (
        Model, CharField, DateField, IntegerField, BooleanField,
)

class Breach(Model):

    name_of_covered_entity = CharField(max_length = 10000)
    state = CharField(max_length = 100)
    covered_entity_type = CharField(max_length = 10000)
    individuals_affected = IntegerField(default = 500)
    breach_submission_date = DateField()
    type_of_breach = CharField(max_length = 10000)
    location_of_breached_information = CharField(max_length = 10000)
    business_associate_present = BooleanField(default = False)
    web_description = CharField(max_length = 100000)
    archive = BooleanField(default = False)

    def __str__(self):
        info = (self.name_of_covered_entity, self.breach_submission_date, 
                self.individuals_affected,)
        return f'Entity Name: %s \n Breach Submission Date: %s \n Individuals Affected: %s' % info

    def is_archived(self):
        return not self.archive
