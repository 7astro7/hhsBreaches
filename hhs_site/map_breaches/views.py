
from django.http import HttpResponse, Http404
from .models import Breach
from django.shortcuts import (
        render, get_object_or_404, get_list_or_404,
)

# need:
# homepage
# year-based archive page
# by month?
# pre covid start, post-covid start
# full US map of:
#   -archive
#   -currently under investigation
# alphabetical by name of covered entity

def privacy_statement(request):
    # a small note contrasting this privacy-respecting app with 
    # bloated surveilling apps of monolithic corporations. it doesn't
    # intersect with surveillance capitalism
    pass

def get_all_breaches(request):
    all_breaches = Breach.objects.order_by('-breach_submission_date')
    context = {'all_breaches': all_breaches}
    return render(request, 'index.html', context)

def index(request):
    #return HttpResponse("What is poppin! You're at the map_breaches index.")
    latest_breaches_list = Breach.objects.order_by('-breach_submission_date')[:10]
#    output = '\n'.join(b.name_of_covered_entity for b in latest_breaches_list)
#    return HttpResponse(output)
    context = {'latest_breaches_list': latest_breaches_list,}
    return render(request, 'index.html', context)

def detail(request, breach_id):
    breach = get_object_or_404(Breach, pk = breach_id)
    return render(request, 'detail.html', {'breach': breach})

def breaches_by_state(request, state):
    breaches_by_state = Breach.objects.filter(state = state)
    context = {'breaches_by_state': breaches_by_state,}
    return render(request, 'state.html', context)

def order_by_largest(request, breach_id):
    pass

def order_by_smallest(request, breach_id):
    pass

def get_earliest_breaches(request, breach_id):
    pass

def get_latest_breaches(request, breach_id):
    pass

def get_archived_breaches(request, breach_id):
    pass

def get_breaches_currently_under_investigation(request, breach_id):
    pass

def archived_breaches(request, breach_id):
    pass

def get_helpful_link_to_more_info(request, breach_id):
    pass


