# --
# Kernel/System/TicketSMSNotificationUtils.pm - All TicketSMSNotificationUtils related functions should be here eventually
# Copyright (C) 2014 Perl-Services.de, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::TicketSMSNotificationUtils;

use strict;
use warnings;

=head1 NAME

Kernel::System::TicketSMSNotificationUtils - utility functions for TicketSMSNotification

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::System::TicketSMSNotificationUtils;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $TicketSMSNotificationUtilsObject = Kernel::System::TicketSMSNotificationUtils->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        DBObject     => $DBObject,
        MainObject   => $MainObject,
        EncodeObject => $EncodeObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(DBObject ConfigObject MainObject LogObject EncodeObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    return $Self;
}

=item RecipientsGet()

Get all recipients

    my %Recipients = $Object->RecipientsGet(
        QueueID    => 12345,
        Action     => 'New', # New|FollowUp|Move
    );

Returns an hash

    (
        # UserID => Mobile number
        123      => '0043913532312',
        45       => '0049963859354',
    )

=cut

sub RecipientsGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed (qw(QueueID Action)) {
        if ( !$Param{$Needed} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );
            return;
        }
    }

    my %ActionMap = (
        New      => 'UserSendNewTicketNotificationSMS',
        Move     => 'UserSendMoveNotificationSMS',
        FollowUp => 'UserSendFollowUpNotificationSMS',
    );

    return if !$ActionMap{ $Param{Action} };

    my $PreferencesTable  = $Self->{ConfigObject}->Get( 'PreferencesTable' );
    my $PreferencesKey    = $Self->{ConfigObject}->Get( 'PreferencesTableKey' );
    my $PreferencesValue  = $Self->{ConfigObject}->Get( 'PreferencesTableValue' );
    my $PreferencesUserID = $Self->{ConfigObject}->Get( 'PreferencesTableUserID' );

    return if !( $PreferencesTable && $PreferencesKey && $PreferencesValue && $PreferencesUserID );

    my $SQL = "SELECT sq.user_id, p2.$PreferencesValue "
        . ' FROM ps_sms_queues sq '
        . "   INNER JOIN $PreferencesTable p "
        . "     ON sq.user_id = p.$PreferencesUserID "
        . "       AND p.$PreferencesKey = ?"
        . "       AND p.$PreferencesValue = 1"
        . "   INNER JOIN $PreferencesTable p2 "
        . "     ON sq.user_id = p2.user_id "
        . ' WHERE sq.queue_id = ? '
        . "   AND p2.$PreferencesKey = 'UserTicketSMSNotificationMobile'";

    return if !$Self->{DBObject}->Prepare(
        SQL  => $SQL,
        Bind => [
            \$ActionMap{ $Param{Action} },
            \$Param{QueueID},
        ],
    );

    my %Recipients;

    ROW:
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        my ($UserID, $Mobile) = @Row;

        $Mobile =~ s{\A\+}{00};
        $Mobile =~ s{[^0-9]+}{}g;

        $Recipients{$UserID} = $Mobile;
    }

    return %Recipients;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

