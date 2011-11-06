package CGIx::Core::Request;

$CGIx::Core::Request = '0.03';

=head1 CGIx::Core::Request

CGIx::Core::Request - Handles CGIx::Core Web requests

=head1 DESCRIPTION

This class handles all Web requests for L<CGIx::Core>, mainly GET and POST 
methods.

=cut

=head2 query_params

Return a value set by the GET method or 0 on failure.

    my $name = $c->req->query_params('name');
    if ($name) {
        $c->stash(name => $name);
    }

=cut

sub query_params {
    my ($self, $key) = @_;

    if (exists $self->{query_params}->{$key}) {
        return $self->{query_params}->{$key};
    }
    else { return 0; }
}

=head2 body_params

Returns the value of the POST method.

    my $username = $c->req->body_params('username');

=cut

sub body_params {
    my ($self, $key) = @_;

    if (exists $self->{body_params}->{$key}) {
        return $self->{body_params}->{$key};
    }
    else { return 0; }
}

=head1 AUTHOR

Brad Haywood <brad@geeksware.net>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

1;
