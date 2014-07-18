# --
# Kernel/Output/HTML/PreferencesPhone.pm
# Copyright (C) 2014 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::PreferencesPhone;

use strict;
use warnings;

use parent 'Kernel::Output::HTML::PreferencesGeneric';

sub Run {
    my ( $Self, %Param ) = @_;

    my ($Mobile) = @{ $Param{GetParam}->{UserTicketSMSNotificationMobile} || [] };
    if ( $Mobile !~ m{\A (?:\+|00) [0-9\s/-]+ \z}xms ) {
        $Self->{Error} = 'The format of the mobile number is invalid. Please use international format, e.g. "+49 123 45236" or "+4911-2351223".';
        return;
    }

    $Self->SUPER::Run( %Param );

    return 1;
}

1;
