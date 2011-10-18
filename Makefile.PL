use inc::Module::Install;

name     'CGIx-Core';
all_from 'lib/CGIx/Core.pm';
author   q{Brad Haywood <brad@geeksware.net>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

