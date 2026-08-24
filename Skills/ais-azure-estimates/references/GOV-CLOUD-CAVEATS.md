# Government Cloud Caveats

## Azure Government Virginia

The MVP guidance and Virtualitics-style sample default to Azure Government
Virginia (`usgovvirginia`). Outputs should display the cloud and region context
in the summary and on affected line items.

Azure Government meter availability through public pricing sources can differ
from commercial Azure. When the Retail Prices API cannot return a reliable Gov
meter, mark the item unresolved or require a documented manual override.
Proposal output must label totals as resolved-item totals when unresolved Gov
items are excluded.

## Azure Government Secret

Do not imply Azure Government Secret availability or pricing unless it has been
confirmed through an authoritative source. Treat Secret dependencies as
confirmation-needed caveats in proposal estimates.

## GPU And Specialized SKUs

GPU, high-memory, specialty networking, and constrained-region SKUs may have
availability or quota limits that materially affect price and feasibility. Flag
these as review items when they appear in an estimate.

## Marketplace Items

Marketplace services and third-party appliances may not map cleanly to public
Azure consumption meters. Exclude them from Azure consumption totals unless a
valid Azure consumption meter or documented manual override is available.

## Reservations And Savings Plans

Reserved-instance and savings-plan assumptions are out of scope for the MVP.
Use pay-as-you-go public retail pricing unless the user explicitly provides an
approved future enhancement path.

## Customer Discounts

Customer-specific discounts and customer agreement pricing are out of scope for
the MVP. Do not present public retail estimates as customer agreement pricing.
If customer pricing may materially change the total, include a reviewer-facing
caveat.
