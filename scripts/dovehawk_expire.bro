##! This script adds per item expiration for MISP intel items. This 
# version does not reset the base time when hits are detected. It is based
# on the intel-extensions package that is Copyright (c) 2016 by Jan Grashoefer

@load base/frameworks/intel

module Intel;

export {
	## Default expiration interval for single intelligence items
	## A negative value disables expiration for these items.
	const dh_per_item_expiration = -1min &redef;

	redef record MetaData += {
		dh_expire: interval &default = dh_per_item_expiration;

		## Internal value tracks time of item creation, last update.
		dh_last_update: time  &default = network_time();
	};
}

hook extend_match(info: Info, s: Seen, items: set[Item])
{
	local matches = |items|;
	for ( item in items )
	{
		local meta = item$meta;
		
		if (meta$source != "MISP") {
			next;
		}
		
		if ( meta$dh_expire > 0 sec && meta$dh_last_update + meta$dh_expire < network_time() )
		{
			# Item already expired
			--matches;
			print fmt("Removing Expired Intel Item: %s",item$indicator);
			remove(item, F);
		}
	}
	
	if ( matches < 1 ) {
		break;
	}
}


hook Intel::item_expired(indicator: string, indicator_type: Type, metas: set[MetaData])
{
	for ( meta in metas )
	{
		if (meta$source != "MISP") {
			next;
		}
	
		# Check for expired items
		if ( meta$dh_expire > 0 sec && meta$dh_last_update + meta$dh_expire < network_time() )
		{
			# Recreate the item from the indicator and meta
			local item: Intel::Item = [
				$indicator = indicator,
				$indicator_type = indicator_type,
				$meta = meta
			];
		
			print fmt("Removing Expired Intel Item: %s",indicator);
			remove(item, F);
		}
	}
}
