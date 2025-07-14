# LATEST FILE
package Opsview::Notifications::Output::Jirasd;
use warnings;
use strict;

use MIME::Base64;
use JSON;
use REST::Client;

use Class::Accessor::Fast;
use base qw(Class::Accessor::Fast);
use Opsview::Crypt;
use Data::Dump qw(pp);
use Log::Log4perl;

__PACKAGE__->mk_accessors(qw(connection_params issue_defaults logger));

=head1 NAME

Opsview::Notifications::Output::Jirasd - Creates a Jira Cloud record

=head1 DESCRIPTION

This module creates an issue in Jira Cloud using REST API v3.
It uses Atlassian Document Format (ADF) for the issue description.

=head1 METHODS

=over 4

=item setup( $c )

Sets up the instance using configuration from $c.

=cut

sub setup {
    my ( $class, $c ) = @_;
    my $self  = $class->new;
    my $crypt = Opsview::Crypt->new();
    my $password;

    $self->logger(Log::Log4perl->get_logger($class));

    unless ( $c->config->{jirasd} ) {
        $self->logger->info("No 'jirasd.yml' configuration found - ignoring notification method");
        return;
    }

    if ( $c->config->{jirasd}->{connection}->{encrypted_password} ) {
        $password = $crypt->decrypt($c->config->{jirasd}->{connection}->{encrypted_password});
    }
    else {
        $password = $c->config->{jirasd}->{connection}->{password};
    }

    $self->issue_defaults( $c->config->{jirasd}->{issue_defaults} || {} );
    $self->connection_params([
        $c->config->{jirasd}->{connection}->{url},
        $c->config->{jirasd}->{connection}->{user},
        $password
    ]);

    return $self;
}

=item process( $c, $data )

Creates a Jira Cloud issue using ADF.

=cut

sub process {
    my ( $self, $c, $data ) = @_;
    my $defaults = { %{ $self->issue_defaults } };

    my $env;
    eval "\$env = $data";
    if ($@) {
        $c->response->{data} = "Error parsing notification data: $@";
        return 0;
    }

    unless ( $defaults->{project_id} || $defaults->{project} ) {
        $c->response->{data} = "Neither project_id nor project found in configuration";
        return 0;
    }
    unless ( $defaults->{type_id} || $defaults->{type} ) {
        $c->response->{data} = "Neither type_id nor type found in configuration";
        return 0;
    }

    $defaults->{type_id} ||= "10001";

    # Only open a Jira issue if it's a PROBLEM notification
    unless ( $env->{NAGIOS_NOTIFICATIONTYPE} eq "PROBLEM" ) {
        $c->response->{data} = "Ignoring non-problem notifications";
        return 0;
    }

    # Create a short text summary for Jira
    my $summary = $env->{NAGIOS_SERVICEDESC}
        ? "$env->{NAGIOS_SERVICEDESC} is $env->{NAGIOS_SERVICESTATE} on host $env->{NAGIOS_HOSTNAME}"
        : "$env->{NAGIOS_HOSTNAME} is $env->{NAGIOS_HOSTSTATE}";
    $summary ||= "Default Summary";

    #
    # Construct an ADF description that includes:
    #   Service: <NAGIOS_SERVICEDESC>
    #   <NAGIOS_HOSTNAME> : <NAGIOS_HOSTADDRESS>
    #   State: <NAGIOS_SERVICESTATE>
    #   Date/Time: <NAGIOS_LONGDATETIME>
    #   Additional Info: <NAGIOS_SERVICEOUTPUT>
    #
    my @adf_content = (
        {
            type    => "paragraph",
            content => [
                { type => "text", text => "Service: $env->{NAGIOS_SERVICEDESC}" }
            ]
        },
        {
            type    => "paragraph",
            content => [
                { type => "text", text => "$env->{NAGIOS_HOSTNAME} : $env->{NAGIOS_HOSTADDRESS}" }
            ]
        },
        {
            type    => "paragraph",
            content => [
                { type => "text", text => "State: $env->{NAGIOS_SERVICESTATE}" }
            ]
        },
        {
            type    => "paragraph",
            content => [
                { type => "text", text => "Date/Time: $env->{NAGIOS_LONGDATETIME}" }
            ]
        },
        {
            type    => "paragraph",
            content => [
                { type => "text", text => "Additional Info: $env->{NAGIOS_SERVICEOUTPUT}" }
            ]
        },
    );

    my $adf_description = {
        version => 1,
        type    => "doc",
        content => \@adf_content
    };

    # Prepare the REST client
    my $jirasd = REST::Client->new();
    my ($url, $username, $password) = @{ $self->connection_params() };
    $url =~ s!/+$!!;  # Remove any trailing slash

    $jirasd->setHost($url . '/rest/api/3');
    $jirasd->addHeader('Content-Type', 'application/json');
    $jirasd->addHeader('Authorization', 'Basic ' . encode_base64("${username}:${password}", ''));

    unless ( $defaults->{project_id} ) {
        $defaults->{project_id} = $defaults->{project};
    }
    my $issuetype_id = "$defaults->{type_id}";

    # Create the payload without extra components
    my $issue_payload = {
        fields => {
            project     => { key => $defaults->{project_id} },
            summary     => $summary,
            description => $adf_description,
            issuetype   => { id => $issuetype_id },
            labels      => [ "OPSVIEW_NOTIFICATION" ],
        }
    };

    # Send the POST request to create the Jira issue
    $jirasd->POST('/issue', encode_json($issue_payload));

    if ( $jirasd->responseCode() eq '201' ) {
        my $new_issue = decode_json($jirasd->responseContent());
        $c->response->{id} = $new_issue->{key};
    }
    else {
        $c->response->{data} = "Failed to create Jira issue: " . $jirasd->responseContent();
        return 0;
    }

    $c->response->{acknowledge} = 1;
    $c->response->{hostname}    = $env->{NAGIOS_HOSTNAME};
    $c->response->{servicename} = $env->{NAGIOS_SERVICEDESC};

    return 1;
}

1;


