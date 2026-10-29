# Pillarwatch -- PRD

> The one-page picture of the finished product. Owner-approved at bootstrap.
> Every feature's `serves:` line points here. If a feature cannot say which
> part of this page it serves, question the feature.

## What and for whom

A self-hosted status page that shows the up/down history of a small team's own services, no third-party dependency.

Primary user: An on-call engineer at a small team who wants an honest status page without paying for or trusting a SaaS status vendor. Problem: Small teams either run no status page (users find out about outages from support tickets) or hand uptime data to a third-party SaaS that is one more thing to trust and pay for.
Today's alternative: a paid third-party status-page SaaS, or no status page at all. Why this wins: single-binary self-hosted install instead of a hosted SaaS subscription

## The journey (end to end)

1. The team registers a service with a health-check URL.
2. Pillarwatch polls it on an interval and records up/down transitions.
3. A public page renders current status and a 90-day history bar per service.

## Surfaces

- Status page
- Service registration

## v1 includes

- Service registration with a health-check URL and poll interval.
- Poller with an up/down/degraded state machine and transition history.
- Public status page with current status and a 90-day history bar per service.

## v1 excludes

- No multi-region or synthetic-transaction checks.
- No paging/alerting integrations in the first cut -- the page itself is the notification.

## Success looks like

- time from real outage to page reflecting it -- under one poll interval
- self-hosted install time -- under 10 minutes on a single binary
