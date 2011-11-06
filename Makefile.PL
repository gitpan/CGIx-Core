use inc::Module::Install;

name     'CGIx-Core';
all_from 'lib/CGIx/Core.pm';
author   q{Brad Haywood <brad@geeksware.net>};
license  'perl';

build_requires 'Test::More';
requires 'Template::Alloy';
requires 'File::Basename';
requires 'YAML::Syck';
requires 'FindBin';

auto_install;

WriteAll;

