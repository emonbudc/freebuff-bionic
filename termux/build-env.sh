#!/usr/bin/env bash
# Public client configuration baked into the Freebuff binary.
#
# These are the production public values; the PostHog and Stripe entries are
# placeholders, matching upstream's CI smoke-test build. Do not add secrets:
# every value here is compiled into the executable with --define.

export NEXT_PUBLIC_CB_ENVIRONMENT=prod
export NEXT_PUBLIC_CODEBUFF_APP_URL=https://www.codebuff.com
export NEXT_PUBLIC_FREEBUFF_APP_URL=https://freebuff.com
export NEXT_PUBLIC_SUPPORT_EMAIL=support@freebuff.com
export NEXT_PUBLIC_POSTHOG_API_KEY=phc_public_placeholder
export NEXT_PUBLIC_POSTHOG_HOST_URL=https://us.i.posthog.com
export NEXT_PUBLIC_STRIPE_PUBLISHABLE_KEY=pk_test_placeholder
export NEXT_PUBLIC_STRIPE_CUSTOMER_PORTAL=https://billing.stripe.com/p/login/test
export NEXT_PUBLIC_WEB_PORT=3000
