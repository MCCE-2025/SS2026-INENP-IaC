#!/usr/bin/env python3
"""Generate the platform architecture diagram using official Google Cloud icons.

This uses the ``diagrams`` library (https://diagrams.mingrammer.com), which
bundles the official Google Cloud Platform icon set (plus Argo CD, GitHub, and
Kubernetes icons) and renders through Graphviz (``dot``) under the hood. It
mirrors the Terraform-provisioned platform: GKE, Argo CD GitOps, External
Secrets Operator, ExternalDNS, Secret Manager, and Cloud DNS.

Outputs ``architecture.png`` and ``architecture.svg`` next to this script.

Usage:
    pip install diagrams        # also requires the Graphviz "dot" binary
    python docs/architecture.py
"""

from __future__ import annotations

from pathlib import Path

from diagrams import Cluster, Diagram, Edge
from diagrams.gcp.compute import GKE, ComputeEngine
from diagrams.gcp.network import DNS, VirtualPrivateCloud
from diagrams.gcp.security import Iam, SecretManager
from diagrams.gcp.storage import GCS
from diagrams.k8s.compute import Deploy
from diagrams.k8s.ecosystem import ExternalDns
from diagrams.k8s.others import CRD
from diagrams.k8s.podconfig import Secret
from diagrams.onprem.client import User
from diagrams.onprem.gitops import Argocd
from diagrams.onprem.vcs import Github

OUTPUT = Path(__file__).with_name("architecture")

# Color palette (loosely aligned with GCP / tooling brand colors).
GCP_GREEN = "#34A853"
GCP_YELLOW = "#FBBC04"
GCP_RED = "#EA4335"
ARGO_ORANGE = "#EF7B4D"
GITHUB_DARK = "#24292E"
TF_PURPLE = "#7B42BC"

GRAPH_ATTR = {
    "fontsize": "22",
    "labelloc": "t",
    "pad": "0.6",
    "nodesep": "0.6",
    "ranksep": "0.9",
    "bgcolor": "white",
    "splines": "spline",
}


def main() -> None:
    with Diagram(
        "SS2026-INENP-IaC \u2014 Platform Architecture",
        filename=str(OUTPUT),
        outformat=["png", "svg"],
        show=False,
        direction="LR",
        graph_attr=GRAPH_ATTR,
    ):
        operator = User("Operator\n(gcloud / terraform / kubectl)")

        with Cluster("GitHub (MCCE-2025 org)"):
            iac_repo = Github("IaC repo\nSS2026-INENP-IaC")
            gitops_repo = Github("GitOps repo\nSS2026-INENP-GitOps")
            github_app = Github("GitHub App\nargocd-gitops-reader")

        with Cluster("Terraform bootstrap (local state)"):
            state_bucket = GCS("GCS state bucket\nterraform-state-<project_id>")

        with Cluster("Google Cloud project"):
            with Cluster("Managed services & IAM"):
                secret_manager = SecretManager("Secret Manager\nargocd-github-app-*")
                cloud_dns = DNS("Cloud DNS\nmanaged zone (existing)")
                sa_eso = Iam("GSA external-secrets\nsecretAccessor")
                wi_extdns = Iam("WI principal external-dns\nroles/dns.admin")

            with Cluster("VPC platform-cluster-vpc"):
                subnet = VirtualPrivateCloud("Subnet\n10.10.0.0/24 (europe-west3)")

                with Cluster("GKE: platform-gke-cluster\n(Workload Identity, Managed Prometheus)"):
                    node_pool = ComputeEngine("Node pool e2-medium\nautoscaling, multi-zone HA")

                    with Cluster("namespace: argocd"):
                        argocd = Argocd("Argo CD\n(Helm release)")
                        project = CRD("AppProject\nplatform")
                        root_app = Argocd("root Application\n(app-of-apps)")
                        gitops_secret = Secret("gitops-repo\n(repo credentials)")

                    with Cluster("namespace: external-secrets"):
                        eso = Deploy("External Secrets\nOperator (Helm)")
                        css = CRD("ClusterSecretStore\ngcp-secret-manager")

                    with Cluster("namespace: external-dns (via GitOps)"):
                        external_dns = ExternalDns("ExternalDNS\n(deployed by Argo CD)")

        # --- Provisioning & operator flow ---------------------------------
        operator >> Edge(label="maintains") >> iac_repo
        operator >> Edge(label="1. bootstrap apply", style="dashed", color=TF_PURPLE) >> state_bucket
        iac_repo >> Edge(label="2. terraform apply", style="dashed", color=TF_PURPLE) >> node_pool
        state_bucket >> Edge(label="remote state", style="dotted", color=TF_PURPLE) >> iac_repo
        operator >> Edge(label="3. upload GitHub App creds", style="dashed", color=GCP_YELLOW) >> secret_manager

        # --- Networking ----------------------------------------------------
        subnet >> Edge(style="invis") >> node_pool

        # --- Argo CD / GitOps ---------------------------------------------
        argocd >> Edge(label="defines", color=ARGO_ORANGE) >> project
        argocd >> Edge(label="manages", color=ARGO_ORANGE) >> root_app
        root_app >> Edge(label="syncs apps from", color=ARGO_ORANGE) >> gitops_repo
        argocd >> Edge(label="clone via GitHub App", style="dashed", color=GITHUB_DARK) >> gitops_repo
        gitops_secret >> Edge(label="repo creds", color=ARGO_ORANGE) >> argocd
        github_app >> Edge(label="read access", style="dotted", color=GITHUB_DARK) >> gitops_repo
        root_app >> Edge(label="deploys", style="dashed", color=GCP_GREEN) >> external_dns

        # --- External Secrets flow ----------------------------------------
        eso >> Edge(label="configures", color=GCP_RED) >> css
        css >> Edge(label="reads secrets (WI)", color=GCP_RED) >> secret_manager
        eso >> Edge(label="syncs -> gitops-repo", color=GCP_RED) >> gitops_secret
        sa_eso >> Edge(label="WI binding", style="dotted", color=GCP_YELLOW) >> eso

        # --- ExternalDNS ---------------------------------------------------
        external_dns >> Edge(label="upserts records (WI)", color=GCP_GREEN) >> cloud_dns
        wi_extdns >> Edge(label="WI binding", style="dotted", color=GCP_YELLOW) >> external_dns


if __name__ == "__main__":
    main()
