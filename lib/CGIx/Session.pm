package CGIx::Session;

=head1 NAME

CGIx::Session - Plugin module for CGIx to handle basic session management

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

CGIx::Session is a basic module to accomodate CGIx::Core. It offers basic 
session management using DB_File to store its data.

    use CGIx::Core;
    use CGIx::Session;

    my $s = CGIx::Session->new;
    my $c = CGIx::Core->new(view => 'main.tt');

    if ($s->session('user')) {
        $c->(logged_in => 1);
        $c->redirect('account/' . $s->session('user'));
    }

    $s->session('user', 'Foo');

=cut

use DB_File;

sub new {
    use Digest::MD5 qw( md5_hex );
    my ($class, $path) = @_;
    my $self = { 'path' => ($path||'/tmp'), 'id' => undef, session => {} };
    if (! defined $ENV{'HTTP_COOKIE'}) {
        my $ssid = md5_hex(localtime() . rand(99));
        my $sid = 'CGIX=' . $ssid;
        $self->{'id'} = $sid;
        print "Set-Cookie: $sid\n";
        tie %{$self->{session}}, "DB_File", $self->{'path'} . '/' . $sid;
    }
    else {
        my $cookies = $ENV{'HTTP_COOKIE'};
        if ($cookies =~ /CGIX=([0-9a-f]{32})/i) {
            $self->{'id'} = $1;
            tie %{$self->{session}}, "DB_File", $self->{'path'} . '/SOYID=' . $1;
        }
        else {
            my $ssid = md5_hex(localtime() . rand(99));
            my $sid = 'CGIX=' . $ssid;
            $self->{'id'} = $sid;
            print "Set-Cookie: $sid\n";
            tie %{$self->{session}}, "DB_File", $self->{'path'} . '/' . $sid;
        }
    }
    bless $self, $class;
    return $self;
}

=head2 session_id

Returns a session id of the cookie

    print "Session ID: " . $s->session_id;

=cut

sub session_id {
    my $self = shift;
    if (defined $self->{'id'}) { return $self->{'id'}; }
    else { return undef; }
}

=head2 session_flush

Closes the session properly

    $s->session_flush;
=cut

sub session_flush {
    my $self = shift;
    untie %{$self->{session}};
}

=head2 session

Sets or returns a session.

    $s->session('user');
    $s->session('user', 'Foo');

=cut

sub session {
    my ($self, $key, $val) = @_;

    if (! $val) { 
        if (exists $self->{session}->{$key}) { return $self->{session}->{$key}; }
        else { return 0; }
    }
    
    if (exists $self->{session}->{$key}) {
        $self->{session}->{$key} = $val;
        return $self->{session}->{$key};
    }
    else { return 0; }
}

1;
