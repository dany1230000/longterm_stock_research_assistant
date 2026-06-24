from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

FORBIDDEN_TERMS = [
    "\u8cb7\u9032",
    "\u8ce3\u51fa",
    "\u52a0\u78bc",
    "\u6e1b\u78bc",
    "\u9032\u5834",
    "\u51fa\u5834",
    "\u5957\u5229",
    "\u9069\u5408\u8cb7",
    "\u4fbf\u5b9c\u53ef\u4ee5\u8cb7",
    "\u592a\u8cb4\u4e0d\u8981\u8cb7",
]


def main() -> int:
    args = _parse_args()
    steps = [
        _required_files_check(),
        _pwa_metadata_check(),
        _readiness_endpoint_check(),
        _analysis_endpoint_check(),
        _run_command("public_config", ["cmd", "/c", "scripts\\00631l_check_public_config.cmd"]),
        _run_command("public_pages", ["cmd", "/c", "scripts\\00631l_check_public_pages.cmd"]),
        _run_command("pages_deploy_status", ["cmd", "/c", "scripts\\00631l_check_pages_deploy.cmd"]),
        _run_command(
            "public_pages_checkup",
            [
                "cmd",
                "/c",
                "scripts\\00631l_public_pages_checkup.cmd",
                "--skip-github-api",
                "--summary-only",
            ],
        ),
        _run_command(
            "pages_deploy_wait_dry_run",
            ["cmd", "/c", "scripts\\00631l_wait_pages_deploy.cmd", "--dry-run"],
        ),
        _run_command(
            "public_release_marker_wait_dry_run",
            [
                "cmd",
                "/c",
                "scripts\\00631l_wait_public_release_marker.cmd",
                "--dry-run",
                "--summary-only",
            ],
        ),
        _run_command("backend_prod_check", ["cmd", "/c", "scripts\\00631l_backend_prod_check.cmd"]),
        _run_command("backend_docker_check", ["cmd", "/c", "scripts\\00631l_backend_docker_check.cmd"]),
        _run_command("deploy_precheck", ["cmd", "/c", "scripts\\00631l_deploy_precheck.cmd"]),
        _run_command(
            "remote_maintenance_dry_run",
            ["cmd", "/c", "scripts\\00631l_remote_maintenance.cmd", "--dry-run"],
        ),
        _run_command(
            "remote_catalog_batch_dry_run",
            [
                "cmd",
                "/c",
                "scripts\\00631l_remote_maintenance.cmd",
                "--mode",
                "daily",
                "--etf-from-catalog",
                "--etf-limit",
                "50",
                "--dry-run",
            ],
        ),
        _run_command(
            "public_backend_status_dry_run",
            ["cmd", "/c", "scripts\\00631l_public_backend_status.cmd", "--dry-run"],
        ),
        _run_command(
            "public_persistence_verifier_dry_run",
            ["cmd", "/c", "scripts\\00631l_verify_public_persistence.cmd", "--dry-run"],
        ),
        _run_command(
            "public_deploy_drift_dry_run",
            ["cmd", "/c", "scripts\\00631l_public_deploy_drift.cmd", "--dry-run"],
        ),
        _run_command(
            "public_deploy_wait_dry_run",
            ["cmd", "/c", "scripts\\00631l_wait_public_deploy.cmd", "--dry-run"],
        ),
        _run_command(
            "public_maintenance_status_dry_run",
            ["cmd", "/c", "scripts\\00631l_public_maintenance_status.cmd", "--dry-run"],
        ),
        _run_command(
            "public_freshness_dry_run",
            ["cmd", "/c", "scripts\\00631l_compare_public_freshness.cmd", "--dry-run"],
        ),
        _run_command(
            "public_history_stability_dry_run",
            ["cmd", "/c", "scripts\\00631l_public_history_stability.cmd", "--dry-run"],
        ),
        _run_command(
            "public_catalog_batches_dry_run",
            [
                "cmd",
                "/c",
                "scripts\\00631l_public_etf_catalog_batches.cmd",
                "--dry-run",
                "--batch-size",
                "1",
                "--max-batches",
                "1",
            ],
        ),
        _run_command("env_check", ["cmd", "/c", "scripts\\00631l_check_env.cmd"]),
        _run_command(
            "dart_format_check",
            ["cmd", "/c", "dart", "format", "--set-exit-if-changed", "."],
        ),
        _run_command("flutter_analyze", ["cmd", "/c", "flutter", "analyze"]),
        _run_command("flutter_test", ["cmd", "/c", "flutter", "test"]),
        _run_command("flutter_build_web", ["cmd", "/c", "flutter", "build", "web"]),
        _run_command(
            "backend_tests",
            ["py", "-m", "unittest", "discover", "-s", "backend\\tests"],
        ),
        _run_command("daily_cycle", ["cmd", "/c", "scripts\\00631l_daily_cycle.cmd"]),
        _run_command("export", ["cmd", "/c", "scripts\\00631l_export_history.cmd"]),
        _run_command("report", ["cmd", "/c", "scripts\\00631l_generate_daily_report.cmd"]),
        _run_command("integrity", ["cmd", "/c", "scripts\\00631l_check_integrity.cmd"]),
        _run_command(
            "retention_dry_run",
            [
                "cmd",
                "/c",
                "scripts\\00631l_apply_retention.cmd",
                "--dry-run",
                "--report-retention-count",
                "30",
            ],
        ),
        _run_command(
            "backup_rotation",
            ["cmd", "/c", "scripts\\00631l_backup_data.cmd", "--retention-count", "30"],
        ),
        _run_command("restore_dry_run", ["cmd", "/c", "scripts\\00631l_restore_dry_run.cmd"]),
        _run_command(
            "price_history_status",
            ["cmd", "/c", "scripts\\00631l_update_price_history.cmd", "--status-only"],
        ),
        _run_command(
            "static_public_data",
            ["cmd", "/c", "scripts\\00631l_export_static_data.cmd", "--status-only"],
        ),
        _run_command(
            "etf_catalog_status",
            ["cmd", "/c", "scripts\\00631l_import_etf_catalog.cmd", "--status-only"],
        ),
        _run_command(
            "etf_price_history_status",
            [
                "cmd",
                "/c",
                "scripts\\00631l_import_etf_price_history.cmd",
                "--status-only",
                "--summary-only",
            ],
        ),
        _run_command("smoke", ["py", "backend\\scripts\\smoke_00631l_live.py"]),
        _forbidden_wording_scan(),
        _run_command("git_diff_check", ["git", "diff", "--check"]),
    ]
    failures = [
        f"{step['name']}: {step['message']}"
        for step in steps
        if step["status"] == "FAIL"
    ]
    warnings = [
        f"{step['name']}: {step['message']}"
        for step in steps
        if step["status"] == "WARN"
    ]
    overall_status = "FAIL" if failures else "WARN" if warnings else "PASS"
    next_action = (
        "Fix failures and rerun scripts\\00631l_release_check.cmd."
        if failures
        else "Review warnings; PASS/WARN is acceptable when warnings are expected local or off-hours data freshness states."
        if warnings
        else "Ready for commit/tag."
    )
    payload = {
        "sourceContract": "00631l_release_check",
        "checkedAt": _now_iso(),
        "overallStatus": overall_status,
        "failures": failures,
        "warnings": warnings,
        "nextAction": next_action,
        "steps": steps,
    }
    printable_payload = payload if args.verbose else _compact_release_check_payload(payload)
    print(json.dumps(printable_payload, ensure_ascii=True, indent=2, sort_keys=True))
    print(
        "[summary] "
        f"overallStatus={overall_status} "
        f"warnings={len(warnings)} "
        f"failures={len(failures)}"
    )
    return 1 if failures else 0


def _compact_release_check_payload(payload: dict[str, Any]) -> dict[str, Any]:
    steps = payload.get("steps") if isinstance(payload.get("steps"), list) else []
    compact_steps: list[dict[str, Any]] = []
    for step in steps:
        if not isinstance(step, dict):
            continue
        compact_steps.append(
            {
                "name": step.get("name"),
                "status": step.get("status"),
                "message": step.get("message"),
                "exitCode": step.get("exitCode"),
            }
        )
    return {
        key: value for key, value in payload.items() if key != "steps"
    } | {
        "stepSummary": compact_steps,
        "stepCount": len(compact_steps),
    }


def _required_files_check() -> dict[str, Any]:
    required_files = [
        "docs/00631l_scheduler_setup.md",
        "docs/00631l_docs_index.md",
        "docs/00631l_mobile_usage.md",
        "docs/00631l_ai_analysis.md",
        "docs/00631l_public_deployment.md",
        "docs/00631l_pwa_usage.md",
        "docs/00631l_app_store_path.md",
        "docs/00631l_app_store_release_plan.md",
        "docs/00631l_v2_2_public_deploy_ready_summary.md",
        "docs/00631l_backtest_guide.md",
        "docs/00631l_position_tracking.md",
        "docs/00631l_data_sources_freshness.md",
        "docs/00631l_v3_0_app_ready_summary.md",
        "docs/00631l_v3_1_static_public_summary.md",
        "docs/00631l_v3_2_standalone_pwa_summary.md",
        "docs/00631l_live_backend_deployment.md",
        "docs/00631l_v3_3_live_public_summary.md",
        "docs/00631l_v3_4_live_backend_summary.md",
        "docs/00631l_v3_5_remote_maintenance_summary.md",
        "docs/00631l_v3_6_app_ui_refresh_summary.md",
        "docs/00631l_v3_7_complete_data_ui_summary.md",
        "docs/00631l_v3_8_market_app_ui_summary.md",
        "docs/00631l_v3_9_mobile_information_architecture_summary.md",
        "docs/00631l_v3_10_mobile_polish_summary.md",
        "docs/00631l_v3_11_section_summaries.md",
        "docs/00631l_v3_12_navigation_settings_summary.md",
        "docs/00631l_v3_13_data_coverage_summary.md",
        "docs/00631l_v3_14_holdings_coverage_summary.md",
        "docs/00631l_v3_15_holdings_mobile_cards_summary.md",
        "docs/00631l_v3_16_overview_first_screen_summary.md",
        "docs/00631l_v3_17_information_hierarchy_summary.md",
        "docs/00631l_v3_18_detail_progressive_disclosure_summary.md",
        "docs/00631l_v3_19_first_screen_speed_layout_summary.md",
        "docs/00631l_v3_20_home_at_a_glance_summary.md",
        "docs/00631l_v3_21_compact_home_summary.md",
        "docs/00631l_v3_22_fast_startup_summary.md",
        "docs/00631l_v3_23_live_cold_start_fallback_summary.md",
        "docs/00631l_v3_24_overview_layout_summary.md",
        "docs/00631l_v3_25_compact_quote_board_summary.md",
        "docs/00631l_v3_26_user_facing_status_labels_summary.md",
        "docs/00631l_v3_27_four_metric_home_summary.md",
        "docs/00631l_v3_28_home_sparkline_exposure_summary.md",
        "docs/00631l_v3_29_first_screen_segmentation_summary.md",
        "docs/00631l_v3_30_home_data_readiness_summary.md",
        "docs/00631l_v3_31_mobile_quote_trim_summary.md",
        "docs/00631l_v3_32_mobile_first_screen_density_summary.md",
        "docs/00631l_v3_33_fast_first_data_load_summary.md",
        "docs/00631l_v3_34_settings_page_cleanup_summary.md",
        "docs/00631l_v3_35_compact_section_headers_summary.md",
        "docs/00631l_v3_36_overview_history_performance_summary.md",
        "docs/00631l_v3_37_overview_metric_grid_summary.md",
        "docs/00631l_v3_38_history_backtest_merge_summary.md",
        "docs/00631l_v3_39_compact_quote_nav_line_summary.md",
        "docs/00631l_v3_40_live_timeout_static_fallback_summary.md",
        "docs/00631l_v3_41_holdings_exposure_compare_summary.md",
        "docs/00631l_v3_42_web_loading_shell_summary.md",
        "docs/00631l_v3_43_yuanta_maintenance_detection_summary.md",
        "docs/00631l_v3_44_live_static_history_merge_summary.md",
        "docs/00631l_v3_45_remote_history_chunk_update_summary.md",
        "docs/00631l_v3_46_first_screen_live_clarity_summary.md",
        "docs/00631l_v3_47_split_adjusted_history_summary.md",
        "docs/00631l_v3_48_home_chart_visible_summary.md",
        "docs/00631l_v3_49_etf_research_room_ia_summary.md",
        "docs/00631l_v4_0_app_store_foundation_summary.md",
        "docs/00631l_v4_1_tx_live_history_controls_summary.md",
        "docs/00631l_v4_7_static_etf_catalog_summary.md",
        "docs/00631l_v4_8_multi_etf_history_import_summary.md",
        "docs/00631l_v4_9_etf_history_selection_summary.md",
        "docs/00631l_v4_10_etf_history_comparison_summary.md",
        "docs/00631l_v4_11_etf_comparison_basket_summary.md",
        "docs/00631l_v4_28_static_export_summary_line.md",
        "docs/00631l_v4_29_legacy_static_tier_summary.md",
        "docs/00631l_v4_30_static_tier_release_guard.md",
        "docs/00631l_v4_31_legacy_static_count_reconcile.md",
        "docs/00631l_v4_32_search_readiness_metadata.md",
        "docs/00631l_v4_33_search_sheet_wording.md",
        "docs/00631l_v4_34_etf_history_metadata_badge.md",
        "docs/00631l_v4_35_selected_history_quality_card.md",
        "docs/00631l_v4_36_chart_date_guidance.md",
        "docs/00631l_v4_37_manual_comparison_default.md",
        "docs/00631l_v4_38_compact_quote_meta.md",
        "docs/00631l_v4_39_selected_overview_quality.md",
        "docs/00631l_v4_40_selected_etf_ai_daily_context.md",
        "docs/00631l_v4_41_selected_etf_split_caveat.md",
        "docs/00631l_v4_42_position_source_context.md",
        "docs/00631l_v4_43_chart_first_overview.md",
        "docs/00631l_v4_44_compact_quote_meta_line.md",
        "docs/00631l_v4_45_selected_quote_source_label.md",
        "docs/00631l_v4_46_backtest_range_chips.md",
        "docs/00631l_v4_47_compact_position_card.md",
        "docs/00631l_v4_48_compact_ai_detail.md",
        "docs/00631l_v4_49_chart_range_touch_hint.md",
        "docs/00631l_v4_50_selected_search_state.md",
        "docs/00631l_v4_51_backend_seed_history_fallback.md",
        "docs/00631l_v4_52_backend_etf_seed_history_fallback.md",
        "docs/00631l_v4_53_remote_etf_history_maintenance.md",
        "docs/00631l_next_direction.md",
        "docs/00631l_v4_54_backend_release_metadata.md",
        "docs/00631l_v4_55_public_backend_status_check.md",
        "docs/00631l_v4_56_public_data_freshness.md",
        "docs/00631l_v4_57_catalog_batch_remote_maintenance.md",
        "docs/00631l_v4_58_backend_release_defaults.md",
        "docs/00631l_v4_59_remote_retry_postcheck.md",
        "docs/00631l_v4_60_catalog_seed_fallback.md",
        "docs/00631l_v4_61_public_catalog_batch_runner.md",
        "docs/00631l_v4_62_public_batch_resilience.md",
        "docs/00631l_v4_63_public_deploy_drift.md",
        "docs/00631l_v4_64_public_catalog_batch_resume.md",
        "docs/00631l_v4_65_public_ready_floor.md",
        "docs/00631l_v4_66_public_maintenance_status.md",
        "docs/00631l_v4_67_public_batch_resume_status.md",
        "docs/00631l_v4_68_public_batch_offset_guidance.md",
        "docs/00631l_v4_69_public_batch_timeout_payload.md",
        "docs/00631l_v4_70_public_batch_failure_detail.md",
        "docs/00631l_v4_71_public_batch_fail_fast.md",
        "docs/00631l_v4_72_public_ready_regression.md",
        "docs/00631l_v4_73_preserve_public_batch_state.md",
        "docs/00631l_v4_74_public_batch_next_offset.md",
        "docs/00631l_v4_75_public_batch_regression_guidance.md",
        "docs/00631l_v4_76_public_history_stability.md",
        "docs/00631l_v4_77_deploy_drift_gitsha_noise.md",
        "docs/00631l_v4_78_public_deploy_wait.md",
        "docs/00631l_v4_79_readonly_persistence_warn.md",
        "docs/00631l_v4_80_persistence_first_maintenance.md",
        "docs/00631l_v4_81_public_batch_preflight.md",
        "docs/00631l_v4_82_public_batch_action_flags.md",
        "docs/00631l_v4_83_public_readiness_batch_gate.md",
        "docs/00631l_v4_84_public_batch_test_state_isolation.md",
        "docs/00631l_v4_85_public_batch_observability.md",
        "docs/00631l_v4_86_public_readiness_probe.md",
        "docs/00631l_v4_87_remote_etf_update_items.md",
        "docs/00631l_v4_88_public_regression_batch_gate.md",
        "docs/00631l_v4_89_public_storage_path_diagnostics.md",
        "docs/00631l_v4_90_public_persistence_marker.md",
        "docs/00631l_v4_91_public_marker_maintenance_summary.md",
        "docs/00631l_v4_92_public_fresh_marker_batch_gate.md",
        "docs/00631l_v4_93_release_metadata_refresh.md",
        "docs/00631l_v4_94_render_persistent_disk_blueprint.md",
        "docs/00631l_v4_95_fresh_marker_readiness_warn.md",
        "docs/00631l_v4_96_public_persistence_verifier.md",
        "docs/00631l_v4_97_public_persistence_sample_guard.md",
        "docs/00631l_v4_98_public_persistence_fail_classification.md",
        "docs/00631l_v4_99_mobile_home_context.md",
        "docs/00631l_v5_0_lazy_comparison_load.md",
        "docs/00631l_v5_1_history_chart_touch_detail.md",
        "docs/00631l_v5_2_etf_comparison_status_cleanup.md",
        "docs/00631l_v5_3_compact_overview_exposure.md",
        "docs/00631l_v5_4_symbol_search_capability_labels.md",
        "docs/00631l_v5_5_history_backtest_range_context.md",
        "docs/00631l_v5_6_position_account_summary.md",
        "docs/00631l_v5_7_daily_ai_analysis_context.md",
        "docs/00631l_v5_8_ai_page_briefing_cards.md",
        "docs/00631l_v5_9_settings_account_summary.md",
        "docs/00631l_v5_10_overview_data_readiness_ribbon.md",
        "docs/00631l_v5_11_symbol_search_history_coverage.md",
        "docs/00631l_v5_12_comparison_basket_labels.md",
        "docs/00631l_v5_13_selected_history_split_status.md",
        "docs/00631l_v5_14_etf_data_library_readiness.md",
        "docs/00631l_v5_15_symbol_search_history_filter.md",
        "docs/00631l_v5_16_selected_etf_readiness_banner.md",
        "docs/00631l_v5_17_overview_chart_date_inspector.md",
        "docs/00631l_v5_18_ai_today_snapshot.md",
        "docs/00631l_v5_19_etf_data_readiness_ratio.md",
        "docs/00631l_v5_20_etf_room_readiness_panel.md",
        "docs/00631l_v5_21_custom_etf_comparison_basket.md",
        "docs/00631l_v5_22_overview_data_time_strip.md",
        "docs/00631l_v5_23_compact_position_account.md",
        "docs/00631l_v5_24_ai_daily_interpretation_matrix.md",
        "docs/00631l_v5_25_etf_data_completion_status.md",
        "docs/00631l_v5_26_history_chart_date_axis.md",
        "docs/00631l_v5_27_etf_catalog_gap_completion.md",
        "docs/00631l_v5_28_etf_import_gap_summary.md",
        "docs/00631l_v5_29_pages_format_alignment.md",
        "docs/00631l_v5_30_release_format_gate.md",
        "docs/00631l_v5_31_etf_data_status_wording.md",
        "docs/00631l_v5_32_compact_overview_ticker.md",
        "docs/00631l_v5_33_overview_chart_priority.md",
        "docs/00631l_v5_34_public_pages_smoke.md",
        "docs/00631l_v5_35_pages_deploy_status.md",
        "docs/00631l_v5_36_pages_deploy_wait.md",
        "docs/00631l_v5_37_public_pages_checkup.md",
        "docs/00631l_v5_38_public_checkup_rate_limit.md",
        "docs/00631l_v5_39_public_release_marker.md",
        "docs/00631l_v5_40_public_release_guidance.md",
        "docs/00631l_v5_41_public_release_mismatch_guidance.md",
        "docs/00631l_v5_42_public_release_wait.md",
        "docs/00631l_v5_43_public_static_release_ui.md",
        "docs/00631l_v5_44_public_release_wait_summary.md",
        "docs/00631l_v5_45_brief_public_release_wait.md",
        "docs/00631l_v5_46_brief_public_pages_checkup.md",
        "docs/00631l_v5_47_brief_release_check.md",
        "docs/00631l_v5_48_selected_etf_data_context.md",
        "docs/00631l_v5_49_selected_etf_ai_briefing.md",
        "docs/00631l_v5_50_selected_etf_history_strip.md",
        "docs/00631l_v5_51_compact_selected_etf_overview.md",
        "docs/00631l_v5_52_selected_etf_overview_dedup.md",
        "docs/00631l_v5_53_etf_selector_confidence.md",
        "docs/00631l_v5_54_comparison_basket_context.md",
        "docs/00631l_v5_55_compact_position_actions.md",
        "docs/00631l_v5_56_ai_daily_interpretation.md",
        "docs/00631l_v5_57_compact_settings_account.md",
        "docs/00631l_v5_58_compact_home_glance.md",
        "docs/00631l_v5_59_compact_backtest_controls.md",
        "docs/00631l_v5_60_compact_position_entry.md",
        "docs/00631l_v5_61_ai_page_progressive_detail.md",
        "docs/00631l_v5_62_static_fast_start.md",
        "docs/00631l_v5_63_compact_etf_search.md",
        "docs/00631l_v5_64_broad_etf_seed_catalog.md",
        "docs/00631l_v5_65_concise_static_pages_build.md",
        "docs/00631l_v5_66_etf_import_progress.md",
        "docs/00631l_v5_67_static_coverage_guard.md",
        "docs/00631l_v5_68_compact_static_output.md",
        "docs/00631l_remote_maintenance.md",
        ".github/workflows/00631l_backend_maintenance.yml",
        "docs/00631l_daily_report_guide.md",
        "deploy/docker-compose.yml",
        "deploy/Caddyfile",
        "deploy/nginx.example.conf",
        "deploy/render.yaml",
        "render.yaml",
        "backend/Dockerfile",
        "backend/app/analysis.py",
        "backend/app/backtest.py",
        "backend/app/price_history.py",
        "backend/seeds/00631l_price_history_seed.jsonl",
        "backend/seeds/twse_etf_catalog_seed.json",
        "backend/seeds/etf_price_history_seed/00631L.jsonl",
        "backend/seeds/etf_price_history_seed/0050.jsonl",
        "backend/seeds/etf_price_history_seed/00940.jsonl",
        "backend/app/taifex_tx.py",
        "backend/app/etf_catalog.py",
        "backend/app/etf_price_history.py",
        "backend/app/static_export.py",
        "backend/app/data_integrity.py",
        "backend/app/data_backup.py",
        "backend/app/restore_dry_run.py",
        "backend/app/retention_policy.py",
        "backend/scripts/check_public_config_00631l.py",
        "backend/scripts/check_public_pages_00631l.py",
        "backend/scripts/check_pages_deploy_status_00631l.py",
        "backend/scripts/wait_pages_deploy_00631l.py",
        "backend/scripts/public_pages_checkup_00631l.py",
        "backend/scripts/wait_public_release_marker_00631l.py",
        "backend/scripts/backend_prod_check_00631l.py",
        "backend/scripts/backend_docker_check_00631l.py",
        "backend/scripts/deploy_precheck_00631l.py",
        "backend/scripts/remote_maintenance_00631l.py",
        "backend/scripts/public_backend_status_00631l.py",
        "backend/scripts/verify_public_persistence_00631l.py",
        "backend/scripts/check_public_deploy_drift_00631l.py",
        "backend/scripts/wait_public_deploy_00631l.py",
        "backend/scripts/public_maintenance_status_00631l.py",
        "backend/scripts/compare_public_data_freshness_00631l.py",
        "backend/scripts/public_history_stability_00631l.py",
        "backend/scripts/run_public_etf_catalog_batches_00631l.py",
        "backend/scripts/import_etf_catalog.py",
        "backend/scripts/import_etf_price_history.py",
        "scripts/00631l_check_public_config.cmd",
        "scripts/00631l_check_public_pages.cmd",
        "scripts/00631l_check_pages_deploy.cmd",
        "scripts/00631l_wait_pages_deploy.cmd",
        "scripts/00631l_public_pages_checkup.cmd",
        "scripts/00631l_wait_public_release_marker.cmd",
        "scripts/00631l_build_web_public.cmd",
        "scripts/00631l_backend_prod_check.cmd",
        "scripts/00631l_backend_docker_check.cmd",
        "scripts/00631l_bootstrap_deploy.cmd",
        "scripts/00631l_deploy_precheck.cmd",
        "scripts/00631l_remote_maintenance.cmd",
        "scripts/00631l_public_backend_status.cmd",
        "scripts/00631l_verify_public_persistence.cmd",
        "scripts/00631l_public_deploy_drift.cmd",
        "scripts/00631l_wait_public_deploy.cmd",
        "scripts/00631l_public_maintenance_status.cmd",
        "scripts/00631l_compare_public_freshness.cmd",
        "scripts/00631l_public_history_stability.cmd",
        "scripts/00631l_public_etf_catalog_batches.cmd",
        "scripts/00631l_import_etf_catalog.cmd",
        "scripts/00631l_import_etf_price_history.cmd",
        "scripts/00631l_validate_etf_price_history.cmd",
        "scripts/00631l_daily_cycle_scheduled.cmd",
        "scripts/00631l_lan_info.cmd",
        "scripts/00631l_start_backend_lan.cmd",
        "scripts/00631l_start_frontend_lan.cmd",
        "scripts/00631l_generate_daily_report.cmd",
        "scripts/00631l_check_integrity.cmd",
        "scripts/00631l_apply_retention.cmd",
        "scripts/00631l_backup_data.cmd",
        "scripts/00631l_restore_dry_run.cmd",
        "scripts/00631l_update_price_history.cmd",
        "scripts/00631l_export_static_data.cmd",
        "scripts/00631l_build_pages_static.cmd",
    ]
    missing = [path for path in required_files if not (ROOT / path).exists()]
    return {
        "name": "maintenance_artifacts",
        "command": "internal required maintenance artifact check",
        "status": "FAIL" if missing else "PASS",
        "message": f"missing {len(missing)} required files" if missing else "ok",
        "exitCode": 1 if missing else 0,
        "missingFiles": missing,
        "stdoutTail": "",
        "stderrTail": "",
    }


def _pwa_metadata_check() -> dict[str, Any]:
    failures = []
    try:
        manifest = json.loads((ROOT / "web" / "manifest.json").read_text(encoding="utf-8"))
        index = (ROOT / "web" / "index.html").read_text(encoding="utf-8")
    except Exception as error:
        return {
            "name": "pwa_metadata",
            "command": "internal web manifest/index metadata check",
            "status": "FAIL",
            "message": str(error),
            "exitCode": 1,
            "stdoutTail": "",
            "stderrTail": str(error),
        }
    manifest_name = str(manifest.get("name") or "")
    manifest_short_name = str(manifest.get("short_name") or "")
    if "ETF 研究室" not in manifest_name or "00631L 正二研究室" not in manifest_name:
        failures.append("manifest name is not ETF/00631L dedicated")
    if manifest_short_name not in {"ETF研究室", "00631L"}:
        failures.append("manifest short_name is not ETF/00631L")
    if manifest.get("start_url") != "./":
        failures.append("manifest start_url does not open root")
    if manifest.get("scope") != "./":
        failures.append("manifest scope is not root")
    if "ETF 研究室" not in index or "00631L 正二研究室" not in index:
        failures.append("index title/app metadata missing ETF/00631L")
    if "LongTerm Stock Research Assistant" in index:
        failures.append("index still exposes generic app title")
    return {
        "name": "pwa_metadata",
        "command": "internal web manifest/index metadata check",
        "status": "FAIL" if failures else "PASS",
        "message": "; ".join(failures) if failures else "ok",
        "exitCode": 1 if failures else 0,
        "stdoutTail": json.dumps(manifest, ensure_ascii=True)[-3000:],
        "stderrTail": "",
    }


def _readiness_endpoint_check() -> dict[str, Any]:
    try:
        from fastapi.testclient import TestClient
        from backend.app.main import app

        response = TestClient(app).get("/ready")
        payload = response.json()
        failures = []
        if response.status_code != 200:
            failures.append(f"status_code={response.status_code}")
        if payload.get("sourceContract") != "00631l_backend_readiness":
            failures.append("missing readiness sourceContract")
        if payload.get("overallStatus") == "FAIL":
            failures.extend(payload.get("failures") or ["readiness failed"])
        status = "FAIL" if failures else "PASS"
        return {
            "name": "readiness_endpoint",
            "command": "internal TestClient GET /ready",
            "status": status,
            "message": "; ".join(str(item) for item in failures) if failures else "ok",
            "exitCode": 1 if failures else 0,
            "stdoutTail": json.dumps(payload, ensure_ascii=True)[-3000:],
            "stderrTail": "",
        }
    except Exception as error:  # pragma: no cover - release guard
        return {
            "name": "readiness_endpoint",
            "command": "internal TestClient GET /ready",
            "status": "FAIL",
            "message": str(error),
            "exitCode": 1,
            "stdoutTail": "",
            "stderrTail": str(error),
        }


def _analysis_endpoint_check() -> dict[str, Any]:
    try:
        from fastapi.testclient import TestClient
        from backend.app.main import app

        response = TestClient(app).get("/api/etf/00631l/analysis/summary")
        payload = response.json()
        failures = []
        if response.status_code != 200:
            failures.append(f"status_code={response.status_code}")
        if payload.get("source") != "rule_based":
            failures.append("source is not rule_based")
        if payload.get("disclaimer") != "\u975e\u8cb7\u8ce3\u5efa\u8b70":
            failures.append("missing non-advice disclaimer")
        if not isinstance(payload.get("bullets"), list):
            failures.append("bullets missing")
        if not isinstance(payload.get("actionItems"), list):
            failures.append("actionItems missing")
        status = "FAIL" if failures else "PASS"
        return {
            "name": "analysis_endpoint",
            "command": "internal TestClient GET /api/etf/00631l/analysis/summary",
            "status": status,
            "message": "; ".join(failures) if failures else "ok",
            "exitCode": 1 if failures else 0,
            "stdoutTail": json.dumps(payload, ensure_ascii=True)[-3000:],
            "stderrTail": "",
        }
    except Exception as error:  # pragma: no cover - defensive release check guard
        return {
            "name": "analysis_endpoint",
            "command": "internal TestClient GET /api/etf/00631l/analysis/summary",
            "status": "FAIL",
            "message": str(error),
            "exitCode": 1,
            "stdoutTail": "",
            "stderrTail": str(error),
        }


def _run_command(name: str, command: list[str]) -> dict[str, Any]:
    completed = subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        check=False,
        env=_subprocess_env(),
    )
    stdout = _decode(completed.stdout)
    stderr = _decode(completed.stderr)
    if completed.returncode != 0:
        status = "FAIL"
        message = f"exitCode {completed.returncode}"
    elif _has_overall(stdout, "FAIL") or _has_overall(stderr, "FAIL"):
        status = "FAIL"
        message = "reported overallStatus FAIL"
    elif _has_overall(stdout, "WARN") or _has_overall(stderr, "WARN"):
        status = "WARN"
        message = "reported overallStatus WARN"
    else:
        status = "PASS"
        message = "ok"
    if (
        name == "static_public_data"
        and status != "FAIL"
        and not _static_summary_has_usable_tiers(stdout)
    ):
        status = "FAIL"
        message = "ETF history tiers unavailable despite ready static ETF history"
    return {
        "name": name,
        "command": " ".join(command),
        "status": status,
        "message": message,
        "exitCode": completed.returncode,
        "stdoutTail": _tail(stdout),
        "stderrTail": _tail(stderr),
    }


def _forbidden_wording_scan() -> dict[str, Any]:
    roots = [
        ROOT / "README.md",
        ROOT / "backend",
        ROOT / "docs",
        ROOT / "lib",
        ROOT / "scripts",
        ROOT / "test",
    ]
    hits: list[str] = []
    for path in _iter_text_files(roots):
        try:
            text = path.read_text(encoding="utf-8")
        except UnicodeDecodeError:
            continue
        for term in FORBIDDEN_TERMS:
            if term in text:
                hits.append(str(path.relative_to(ROOT)))
                break
    return {
        "name": "forbidden_wording_scan",
        "command": "internal unicode-escaped forbidden wording scan",
        "status": "FAIL" if hits else "PASS",
        "message": "hits found" if hits else "ok",
        "exitCode": 1 if hits else 0,
        "hits": hits,
        "stdoutTail": "",
        "stderrTail": "",
    }


def _subprocess_env() -> dict[str, str]:
    env = os.environ.copy()
    clean_flutter = Path("C:/src/flutter-clean/bin")
    if clean_flutter.exists():
        env["PATH"] = f"{clean_flutter};{env.get('PATH', '')}"
    return env


def _iter_text_files(roots: list[Path]) -> list[Path]:
    files: list[Path] = []
    ignored_parts = {
        ".dart_tool",
        ".git",
        ".idea",
        "build",
        "backups",
        "data",
        "exports",
        "reports",
        "__pycache__",
    }
    allowed_suffixes = {".dart", ".py", ".md", ".cmd", ".ps1", ".txt", ".json", ".yaml", ".yml"}
    for root in roots:
        if root.is_file():
            files.append(root)
            continue
        if not root.exists():
            continue
        for path in root.rglob("*"):
            if not path.is_file():
                continue
            try:
                relative_parts = set(path.relative_to(ROOT).parts)
            except ValueError:
                relative_parts = set(path.parts)
            if relative_parts & ignored_parts:
                continue
            if path.suffix.lower() in allowed_suffixes:
                files.append(path)
    return files


def _has_overall(text: str, status: str) -> bool:
    return (
        f'"overallStatus": "{status}"' in text
        or f"overallStatus {status}" in text
        or f"overallStatus={status}" in text
    )


def _static_summary_has_usable_tiers(text: str) -> bool:
    if "tiers=not_available" not in text:
        return True
    match = re.search(r"\betfReady=(\d+)\b", text)
    if match is None:
        return True
    return int(match.group(1)) == 0


def _decode(data: bytes) -> str:
    for encoding in ("utf-8", "cp950", "mbcs"):
        try:
            return data.decode(encoding)
        except (LookupError, UnicodeDecodeError):
            continue
    return data.decode("utf-8", errors="replace")


def _tail(text: str, *, max_lines: int = 24) -> str:
    return "\n".join(text.splitlines()[-max_lines:])


def _now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run 00631L release validation with concise output by default.",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print full per-step stdout/stderr tails for debugging.",
    )
    return parser.parse_args()


if __name__ == "__main__":
    raise SystemExit(main())
