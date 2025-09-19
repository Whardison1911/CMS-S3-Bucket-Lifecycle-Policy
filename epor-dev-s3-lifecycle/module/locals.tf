# -----------------------------------------------------------------------------
# File: locals.tf
# Purpose: Centralize datasets, identifiers, and lifecycle transitions for the EPOR DEV S3 module.
# Owner: ZTMF (CMS)
# Notes:
#   - Defines dataset retention and (optional) documentation diagram paths
#   - Declares required bucket identifiers (e.g., hdt, haa)
#   - Maps retention days to storage-class transitions (STANDARD_IA/GLACIER_IR)
#   - Builds dataset × identifier combinations for for_each usage
#   - Consumed by module/main.tf to name, tag, and configure S3 buckets
#   - Update here to change retention/naming globally
#   - Last updated: 2025-09-18
# -----------------------------------------------------------------------------

locals {
  datasets = {
    APS            = { retention = 1,   diagram = "EPOR-APS-1day-RetentionPolicy.png" }
    OnePILov       = { retention = 30,  diagram = "epor-dev-onepilov-30dayRetentionPolicy.png" }
    eSMD           = { retention = 30,  diagram = "epor-dev-onepilov-30dayRetentionPolicy.png" }
    MDP            = { retention = 30,  diagram = "epor-dev-onepilov-30dayRetentionPolicy.png" }
    PreclusionList = { retention = 90,  diagram = "epor-dev-preclusion-90DayRetentionPolicy.png" }
    HETS           = { retention = 180, diagram = "" }
  }

  identifiers = ["hdt", "haa"]

  transition_map = {
    1   = []
    30  = [{ days = 7,  class = "STANDARD_IA" }]
    90  = [{ days = 30, class = "STANDARD_IA" }, { days = 60, class = "GLACIER_IR" }]
    180 = [{ days = 30, class = "STANDARD_IA" }, { days = 90, class = "GLACIER_IR" }]
  }

  combos = flatten([
    for d, cfg in local.datasets : [
      for id in local.identifiers : {
        key        = lower("${d}-${id}")
        dataset    = d
        identifier = id
        retention  = cfg.retention
      }
    ]
  ])

  combos_map = { for c in local.combos : c.key => c }
}
