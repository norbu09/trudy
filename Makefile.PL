use inc::Module::Install;

name     'Trudy';
all_from 'lib/Trudy.pm';
author   q{Lenz Gschwendtner <norbu09@cpan.org>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

