package CGIx::Core;

use Template::Alloy;
use File::Basename 'fileparse';

=head1 NAME

CGIx::Core - Rapid, Simple CGI application development

=head1 VERSION

Version 0.02

=cut

$CGIx::CORE::VERSION = '0.02';

=head1 DESCRIPTION

This module can be used to create quick CGI applications using the excellent Template::Alloy. 
Now you can use the power of CGI (as powerful as it can be) with a template engine instead of 
writing multiple print commands in your script. Separate the code from HTML.
Use 'views' as your layout, then the templates are the content inside the view.

=head1 SYNOPSIS

    ## index.pl (main script)
    #!/usr/bin/env perl
    
    use CGIx::Core;

    my $c = CGIx::Core->new(view => 'default.tt');
    
    $c->stash(
        title => 'My First App',
        greet => 'Hello, World!',
    );

    $c->process; # will use index.tt in templates/ as default
    # $c->process('use_this_template.tt'); # to use a different one

    ## view/default.tt
    <!-- HTML for application "layout" -->
    <!doctype html>
    <html>
        <head>
            <title><% title %></title>
        </head>
        <body>
            <% content %>
        </body>
    </html>
    
    ## template/index.tt
    <h3><% greet %></h3>

=cut
    
=head2 new

Creates a new instance of CGIx::Core. Handles POST and GET 
queries, which will one day be moved to a separate module.
You also set the view here.

    $c = CGIx::Core->new(view => 'default.tt');

=cut

sub new {
    my ($class, %args) = @_;
    $self = {
        template_path => 'template'||$args{template_path},
        wrapper => $args{view}||undef,
        query_params => {},
    };

    $self->{stash} = {};

    if (defined $args{config}) {
        print "Getting config\n";
        our $config = {};
        do "$args{config}";
        $self->{c} = \%$config;
    }
    
    bless $self, $class;
    my $method = $ENV{'REQUEST_METHOD'}; 
    my $qs = (exists $ENV{'QUERY_STRING'}) ? $ENV{'QUERY_STRING'} : undef;
    $self->do_GET($qs) if ($qs);
    $self->do_POST if (defined $method && $method eq 'POST');
    return $self;
}

=head2 stash

stash can be used to set global variables while the current page is available. 
They can be used throughout the view and templates, too.

    $c->stash(title => 'My App');
    $c->stash(
        title   => 'My App',
        foo     => 'baz',
        bar     => 'foo'.
    );

=cut

sub stash {
    my ($self, %a) = @_;
    for (keys %a) {
        $self->{stash}->{$_} = $a{$_};
    }
}

sub do_GET {
    my ($self, $qs) = @_;
    my @res = ();
    if (index($qs, '&') != -1) {
        my @s = split('&', $qs);
        foreach (@s) {
            @res = split('=', $_);
            #$_GET{$res[0]} = $self->url_decode($res[1]);
            $self->{query_params}->{$res[0]} = $self->url_decode($res[1]);
        }
    }
    else {
        @res = split('=', $qs);
        $self->{query_params}->{$res[0]} = $self->url_decode($res[1]);
        #$_GET{$res[0]} = $self->url_decode($res[1]);
    }
    return 1;
}

sub do_POST {
    my $self = shift;
    $self->{body_params} = {};
    my $ps;
    read( STDIN, $ps, ($ENV{'CONTENT_LENGTH'}||350) );
    if (length $ps > 0) {
        my @res = ();
        if (index($ps, '&') != -1) {
            my @s = split('&', $ps);
            foreach (@s) {
                @res = split('=', $_);
                #$_POST{$res[0]} = $self->url_decode($res[1]);
                $self->{body_params}->{$res[0]} = $self->url_decode($res[1]);    
            }
        }
        else {
            @res = split('=', $ps);
            #$_POST{$res[0]} = $self->url_decode($res[1]);
            $self->{body_params}->{$res[0]} = $self->url_decode($res[1]);    
        }
    }
    return;
}

=head2 redirect

Redirects the user to a different page. Redirects need to be done before the headers are 
sent to the browser. ie: before the process method.

    $c->redirect('users/add.pl');

=cut

sub redirect {
    my $self = shift;
    my $uri = shift;
    my $time = shift||0;
    print "Refresh: $time; url=$uri\r\n";
    print "Content-type: text/html\r\n";
    print "\r\n";
    exit;
}

# Reference: http://glennf.com/writing/hexadecimal.url.encoding.html
=head2 url_decode

Turns all HTML characters into human readable stuff. This is 
automatically called when you get POST or GET data

=cut

sub url_decode {
    my ($self, $string) = @_;
    $string =~ tr/+/ /;
    $string =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
    $string =~ s/<!--(.|\n)*-->//g;
    return $string;
}

=head2 url_encode

This works the same as url_decode, except around the other way.

=cut

sub url_encode {
    my ($self, $string) = @_;
    my $MetaChars = quotemeta( ';,/?\|=+)(*&^%$#@!~`:');
    $string =~ s/([$MetaChars\"\'\x80-\xFF])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
    $string =~ s/ /\+/g;
    return $string;
}

sub include {
    my ($self, $template) = @_;

    require $self->{template_path} . '/' . $template . '.pl';
}

sub view {
    my ($self, $v) = @_;

    $self->{stash}->{template}->process(
        "$v.tt",
        $self->{stash}
    );
}

=head2 process

Runs the view and template. When you've finished all your code, then you 
run this. Without any arguments it will use the filename (minus the extension) as 
the template name.

    ## about.pl
    $c->process; # runs $c->{template_path}/about.tt
    $c->process('about_us'); # runs $c->{template_path}/about_us.tt

=cut

sub process {
    my ($self, $temp, $var) = @_;
    use FindBin;
    print "Content-Type: text/html; charset: utf-8;\n\n";    
    $self->{stash}->{tt} = Template::Alloy->new(
            INCLUDE_PATH => [$self->{template_path}, "$FindBin::Bin"],
            WRAPPER      => "view/$self->{wrapper}"||undef,
            START_TAG => quotemeta('<%'),
            END_TAG   => quotemeta('%>'),
    );
    my $fname = $0;
    my ($name, $path, $suffix) = fileparse($fname, '\.[^\.]*');
    $self->{stash}->{tt}->process($temp||$name . '.tt', $self->{stash}, $var||undef);
}

=head2 query_params

Return a value set by the GET method or 0 on failure.

    if ($c->query_params('name')) { $c->stash(name => $c->query_params('name'); }
    else { $c->stash(name => 'Anonymous'); }

=cut

sub query_params {
    my ($self, $key) = @_;

    if (exists $self->{query_params}->{$key}) {
        return $self->{query_params}->{$key};
    }
    else { return 0; }
}

=head2 body_params

The same as query_params but for POST requests.

    $c->stash(password => $c->body_params('password'));

=cut

sub body_params {
    my ($self, $key) = @_;

    if (exists $self->{body_params}->{$key}) {
        return $self->{body_params}->{$key};
    }
    else { return 0; }
}

1;

