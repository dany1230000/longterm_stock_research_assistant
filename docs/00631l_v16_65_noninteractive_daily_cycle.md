# 00631L v16.65 Noninteractive Daily Cycle

This maintenance pass removes the most common `.cmd` wrappers from the Python
daily cycle runner.

- Collection now calls `collect_00631l_snapshot.py` directly.
- Export now calls `export_00631l_history.py` directly.
- Live smoke now calls `smoke_00631l_live.py` directly.
- Integrity now calls `check_00631l_data_integrity.py` directly.
- The runner still loads `backend/.env` into subprocess environment variables
  so live-source settings behave like the old command wrappers.

The Windows `.cmd` helper files remain available for manual use, but the Python
daily cycle path is now safer for noninteractive validation.
