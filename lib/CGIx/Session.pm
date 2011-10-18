package CGIx::Session;

=head1 NAME

CGIx::Session - Plugin module for CGIx to handle basic session management

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

CGIx::Session is a basic module to accomodate CGIx::Core. It offers basic 
session management using YAML::Syck to store its data.

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

use YAML::Syck;

sub new {
    use Digest::MD5 qw( md5_hex );
    my ($class, $path) = @_;
    my $self = { 'path' => ($path||'/tmp'), 'id' => undef, session => {} };
    
    bless $self, $class;
    if (! defined $ENV{'HTTP_COOKIE'}) {
        my $ssid = md5_hex(localtime() . rand(99));
        my $sid = 'CGIX=' . $ssid;
        $self->{'id'} = $sid;
        print "Set-Cookie: $sid\n";
        #tie %{$self->{session}}, "DB_File", $self->{'path'} . '/' . $sid;
        
        __PACKAGE__->_new_yml($self->{'path'} . '/' . $sid . '.yml');
        $self->{dump_file} = $self->{'path'} . '/' . $sid . '.yml';
        $self->{session} = LoadFile($self->{'path'} . '/' . $sid . '.yml');
    }
    else {
        my $cookies = $ENV{'HTTP_COOKIE'};
        if ($cookies =~ /CGIX=([0-9a-f]{32})/i) {
            $self->{'id'} = $1;
            my $path = $self->{'path'} . '/' . '/CGIX=' . $1 . '.yml';
            if (! -f $path) { __PACKAGE__->_new_yml($self->{'path'} . '/' . '/CGIX=' . $1 . '.yml'); }
            
            $self->{dump_file} = $self->{'path'} . '/' . '/CGIX=' . $1 . '.yml';
            $self->{session} = LoadFile($self->{'path'} . '/' . '/CGIX=' . $1 . '.yml');
        }
        else {
            my $ssid = md5_hex(localtime() . rand(99));
            my $sid = 'CGIX=' . $ssid;
            $self->{'id'} = $sid;
            print "Set-Cookie: $sid\n";
            my $path = $self->{'path'} . '/' . $sid . '.yml';
            if (! -f $path) { __PACKAGE__->_new_yml($self->{'path'} . '/' . $sid . '.yml'); }
            
            $self->{dump_file} = $self->{'path'} . '/' . $sid . '.yml';
            $self->{session} = LoadFile($self->{'path'} . '/' . $sid . '.yml');
        }
    }
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
    else {
        $self->{session}->{$key} = $val;
        return $self->{session}->{$key};
    }
}

sub _new_yml {
    my ($class, $file) = @_;
    open(my $yml, ">$file") or return 0;
    print $yml "---\n";
    close $yml;
    return 1;
}

sub DESTROY {
    my $self = shift;

    DumpFile($self->{dump_file}, $self->{session});
    use Data::Dumper;
    print Dumper($self->{session}) . "\n";
}
1;
