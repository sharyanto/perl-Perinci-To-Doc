package Perinci::Sub::To::Text;

# DATE
# VERSION

use 5.010001;
use Log::ger;
use Moo;

use Locale::TextDomain::UTF8 'Perinci-To-Doc';

extends 'Perinci::Sub::To::FuncBase';
with    'Perinci::To::Doc::Role::Section::AddTextLines';

sub BUILD {
    my ($self, $args) = @_;
}

# because we need stuffs in parent's gen_doc_section_arguments() even to print
# the name, we'll just do everything in after_gen_doc().
sub after_gen_doc {
    my ($self) = @_;

    my $meta  = $self->meta;
    my $dres  = $self->{_doc_res};

    my $orig_result_naked = $meta->{_orig_result_naked} // $meta->{result_naked};

    $self->add_doc_lines(
        "+ ".$dres->{name}.$dres->{args_plterm}.' -> '.$dres->{human_ret},
    );
    $self->inc_doc_indent;

    $self->add_doc_lines("", $dres->{summary})     if $dres->{summary};
    $self->add_doc_lines("", $dres->{description}) if $dres->{description};
    if (keys %{$dres->{args}}) {
        use experimental 'smartmatch';
        $self->add_doc_lines(
            "",
            __("Arguments") .
                ' (' . __("'*' denotes required arguments") . '):',
            "");
        my $i = 0;
        my $arg_has_ct;
        for my $name (sort keys %{$dres->{args}}) {
            my $prev_arg_has_ct = $arg_has_ct;
            $arg_has_ct = 0;
            my $ra = $dres->{args}{$name};
            next if 'hidden' ~~ @{ $ra->{arg}{tags} // [] };
            $self->add_doc_lines("") if $i++ > 0 && $prev_arg_has_ct;
            $self->add_doc_lines(join(
                "",
                "- ", $name, ($ra->{arg}{req} ? '*' : ''), ' => ',
                $ra->{human_arg},
                (defined($ra->{human_arg_default}) ?
                     " (" . __("default") .
                         ": $ra->{human_arg_default})" : "")
            ));
            if ($ra->{summary} || $ra->{description}) {
                $arg_has_ct++;
                $self->inc_doc_indent(2);
                $self->add_doc_lines($ra->{summary}.".") if $ra->{summary};
                if ($ra->{description}) {
                    $self->add_doc_lines("", $ra->{description});
                }
                $self->dec_doc_indent(2);
            }
        }
    }

    if ($meta->{dies_on_error}) {
        $self->add_doc_lines("", __("This function dies on error."), "");
    }

    $self->add_doc_lines("", __("Return value") . ':');
    $self->inc_doc_indent;
    $self->add_doc_lines(__(
"Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information."))
        unless $orig_result_naked;
    $self->add_doc_lines($dres->{res_summary} . ($dres->{res_schema} ? " ($dres->{res_schema}[0])" : "")) if $dres->{res_summary};

    $self->dec_doc_indent;

    $self->dec_doc_indent;
}

1;
# ABSTRACT: Generate text documentation from Rinci function metadata

=for Pod::Coverage .+

=head1 SYNOPSIS

 use Perinci::Sub::To::Text;

 my $doc = Perinci::Sub::To::Text->new(meta => {...});
 say $doc->gen_doc;

You can also try the L<peri-doc> script with the C<--format text> option:

 % peri-doc --format text /Some/Module/somefunc

To generate a usage-like help message for a function, you can try
L<peri-func-usage> which is included in the L<Perinci::CmdLine::Classic>
distribution.

 % peri-func-usage http://example.com/api/somefunc

=cut
