use feature 'say';
use lib 'lib';
use strict;
use warnings;

use B::Deparse;
use Devel::Size 'total_size';
use Dumbbench;
use Template::Alloy;

my @args = ( AUTO_FILTER => 'html', COMPILE_PERL => 1 );

my $og = Template::Alloy->new(@args);
my $ng = Template::Alloy->new( @args, NG => 1 );

my $tmpl = <<'EOF';
[% IF error %]
    <div class=error>[% error %]
[% END %]

[% template %]

<table>
    <tr>
        <th>ISBN
        <th>Title
        <th>Author
        <th>In Stock
[% FOR book IN books %]
    <tr>
        <td>[% book.isbn %]
        <td>[% book.title %]
        <td>[% book.author %]
    [% IF book.in_stock %]
        <td class=green>Yes
    [% ELSE %]
        <td class=red>No
    [% END %]
[% END %]
</table>

[% IF pages > 1 %]
    <a href=/next>next</a>
[% END %]
EOF

my $vars = {
    books => [
        {   author   => 'Herman Melville',
            in_stock => 1,
            isbn     => 9787806261279,
            title    => 'Moby-Dick',
        },
        {   author   => 'James Joyce',
            in_stock => 0,
            isbn     => 9781494405496,
            title    => 'Ulysses',
        },
    ],
};

my $b = B::Deparse->new;

delete @{ $og->load_template(\$tmpl) }{qw/_content _tree/};

say $b->coderef2text( my $og_code = $og->load_template(\$tmpl)->{_perl}{code} );
say $b->coderef2text( my $ng_code = $ng->load_template(\$tmpl)->{_perl}{code} );

say total_size $og_code;
say total_size $ng_code;

$og->process( \$tmpl, $vars );
$ng->process( \$tmpl, $vars );

__END__

my $bench = Dumbbench->new(
    initial_runs         => 1000,
    target_rel_precision => .001,
);

$bench->add_instances(
    Dumbbench::Instance::PerlSub->new(
        code => sub { $og->process( \$tmpl, $vars, \my $out ) },
        name => 'og',
    ),
    Dumbbench::Instance::PerlSub->new(
        code => sub { $ng->process( \$tmpl, $vars, \my $out ) },
        name => 'ng',
    ),
);

$bench->run;
$bench->report;
