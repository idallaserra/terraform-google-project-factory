/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  subnet_01 = "${var.network_name}-subnet-01"
}

/******************************************
  Provider configuration
 *****************************************/
provider "google" {
  version = "~> 3.6.0"
  region      = var.region
  zone        = var.zone
}

provider "google-beta" {
  version = "~> 3.6.0"
}

provider "null" {
  version = "~> 2.1"
}

provider "random" {
  version = "~> 2.2"
}

/******************************************
  Host Project Creation
 *****************************************/
module "host-project" {
  source            = "../../"
  random_project_id = false
  name              = var.host_project_name
  org_id            = var.organization_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account
}

/******************************************
  Network Creation
 *****************************************/
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 2.1.0"

  project_id   = module.host-project.project_id
  network_name = var.network_name

  delete_default_internet_gateway_routes = true
  shared_vpc_host                        = true

  subnets = [
    {
      subnet_name   = local.subnet_01
      subnet_ip     = var.subnet_ip
      subnet_region = var.region
    },
  ]
}

/******************************************
  Service Project Creation
 *****************************************/
module "service-project" {
  source = "../../modules/shared_vpc"

  name              = var.service_project_name
  random_project_id = false

  org_id             = var.organization_id
  folder_id          = var.folder_id
  billing_account    = var.billing_account
  shared_vpc_enabled = true

  shared_vpc         = module.vpc.project_id
  shared_vpc_subnets = module.vpc.subnets_self_links

  activate_apis = [
    "compute.googleapis.com",
    "container.googleapis.com",
  ]

  disable_services_on_destroy = "false"
}

