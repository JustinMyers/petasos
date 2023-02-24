## [Unreleased]

## [0.5.4] - 2023-02-24

Use login shell on remote to have access to petasos command.

## [0.5.3] - 2023-02-24

Changed how locking works for locations and distribution. Should be possible for distributors to location themselves.

## [0.5.2] - 2023-02-22

Bugfix: do not delete seen files on the distributor. Instead, make a workspace directory and put working seen_ files in there.

## [0.5.1] - 2023-02-22

- double run protection with petasos_is_running file
- run petasos locations on node initialization
- run petasos locations after completing exports
- run petasos locations before distribution begins
- test runners simplified

## [0.5.0] - 2023-02-22

- Do not export files to locations that have already seen them.
- Run petasos locations on locations after exports and backfills.
- Logging after taking these actions.
- petasos command now accepts locations argument to ignore distribution.

## [0.4.3] - 2023-02-21

Canonical non-exporting pools now update the manifest.

## [0.4.2] - 2023-02-21

Logging messages and replace rsync with scp.

## [0.4.1] - 2023-02-20

Bugfix.

## [0.4.0] - 2023-02-20

Added rsync-path to distribution config so you can set the location of the rsync on the remote server. Old OSX versions do not play nice with --ignore-missing-args.

## [0.1.0] - 2023-02-02

- Initial release
