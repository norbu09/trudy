use inc::Module::Install;

name     'Trudy';
all_from 'lib/Trudy.pm';
author   q{Lenz Gschwendtner <norbu09@cpan.org>};
license  'perl';

build_requires 'Test::More';

requires 'Config::General';
requires 'File::ShareDir';
requires 'Getopt::Long';
requires 'Pod::Usage';
requires 'Template::Alloy';
requires 'XML::LibXML::Simple';
requires 'DBD::SQLite';
requires 'Mojolicious::Lite';

auto_install;

WriteAll;
