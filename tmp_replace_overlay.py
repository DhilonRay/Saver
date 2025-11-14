from pathlib import Path

path = Path('lib/home_user/home_user.dart')
text = path.read_text()
start = text.index("                // Overlay controls on top of map")
end = text.index("                // Zoom controls positioned on the right side")
new_block = """                // Overlay controls on top of map
                SafeArea(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: overlayMaxHeight,
                            ),
                            child: SingleChildScrollView(
                              padding: EdgeInsets.only(bottom: 16),
                              physics: BouncingScrollPhysics(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    margin: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.5),
                                          blurRadius: 20,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(16),
                                          child: TextField(
                                            controller: controller.destinationController,
                                            style: TextStyle(
                                              color: Colors.blueGrey.shade800,
                                              fontSize: 16,
                                            ),
                                            onChanged: controller.onDestinationTextChanged,
                                            decoration: InputDecoration(
                                              hintText: 'Enter destination',
                                              hintStyle: TextStyle(
                                                color: Colors.blueGrey.shade400,
                                                fontSize: 16,
                                              ),
                                              prefixIcon: Container(
                                                margin: EdgeInsets.all(12),
                                                child: Icon(
                                                  Icons.location_on_outlined,
                                                  color: primaryBlue,
                                                  size: 24,
                                                ),
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8.0),
                                                borderSide: BorderSide.none,
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8.0),
                                                borderSide: BorderSide.none,
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8.0),
                                                borderSide: BorderSide(
                                                  color: primaryBlue,
                                                  width: 2,
                                                ),
                                              ),
                                              filled: true,
                                              fillColor: Colors.grey.shade50,
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Obx(() {
                                          final query = controller.destinationQuery.value.trim();
                                          final showSuggestions = query.isNotEmpty &&
                                              (controller.placeSuggestions.isNotEmpty ||
                                                  controller.isLoadingSuggestions.value);

                                          if (!showSuggestions) {
                                            return SizedBox.shrink();
                                          }

                                          return Container(
                                            margin: EdgeInsets.only(bottom: 16, left: 16, right: 16),
                                            constraints: BoxConstraints(
                                              maxHeight: 300,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12.0),
                                              border: Border.all(
                                                color: Colors.grey.shade200,
                                                width: 1,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.05),
                                                  blurRadius: 8,
                                                  offset: Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: controller.isLoadingSuggestions.value
                                                ? Container(
                                                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                                                    child: Row(
                                                      children: [
                                                        HorizontalRotatingDots(
                                                          size: 20,
                                                          colors: [primaryBlue, secondaryBlue, accentBlue],
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : ListView.builder(
                                                    shrinkWrap: true,
                                                    padding: EdgeInsets.zero,
                                                    physics: ClampingScrollPhysics(),
                                                    itemCount: controller.placeSuggestions.length > 5
                                                        ? 5
                                                        : controller.placeSuggestions.length,
                                                    itemBuilder: (context, index) {
                                                      final place = controller.placeSuggestions[index];
                                                      return InkWell(
                                                        onTap: () => controller.selectPlace(place),
                                                        borderRadius: BorderRadius.circular(12),
                                                        child: Container(
                                                          padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                                                          decoration: BoxDecoration(
                                                            border: index <
                                                                    (controller.placeSuggestions.length > 5
                                                                        ? 4
                                                                        : controller.placeSuggestions.length - 1)
                                                                ? Border(
                                                                    bottom: BorderSide(
                                                                        color: Colors.grey.shade100, width: 1))
                                                                : null,
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Container(
                                                                padding: EdgeInsets.all(8),
                                                                decoration: BoxDecoration(
                                                                  color: lightBlue,
                                                                  borderRadius: BorderRadius.circular(8),
                                                                ),
                                                                child: Icon(
                                                                  Icons.location_on_outlined,
                                                                  size: 20,
                                                                  color: primaryBlue,
                                                                ),
                                                              ),
                                                              SizedBox(width: 16),
                                                              Expanded(
                                                                child: Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  mainAxisSize: MainAxisSize.min,
                                                                  children: [
                                                                    Text(
                                                                      place['name']?.toString() ?? 'Unknown Place',
                                                                      style: TextStyle(
                                                                        color: Colors.blueGrey.shade800,
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.w500,
                                                                      ),
                                                                      maxLines: 1,
                                                                      overflow: TextOverflow.ellipsis,
                                                                    ),
                                                                    if (place['formattedAddress'] != null &&
                                                                        (place['formattedAddress'] as String?)
                                                                                ?.isNotEmpty ==
                                                                            true)
                                                                      Padding(
                                                                        padding: EdgeInsets.only(top: 2),
                                                                        child: Text(
                                                                          place['formattedAddress']?.toString() ?? '',
                                                                          style: TextStyle(
                                                                            color: Colors.blueGrey.shade500,
                                                                            fontSize: 12,
                                                                          ),
                                                                          maxLines: 1,
                                                                          overflow: TextOverflow.ellipsis,
                                                                        ),
                                                                      ),
                                                                  ],
                                                                ),
                                                              ),
                                                              Icon(
                                                                Icons.chevron_right,
                                                                color: Colors.grey.shade400,
                                                                size: 20,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                  Obx(() {
                                    if (controller.destinationPosition.value != null &&
                                        controller.partnerRates.isNotEmpty) {
                                      final firstPartnerRates =
                                          controller.partnerRates.values.firstWhere(
                                        (rates) => rates.isNotEmpty,
                                        orElse: () => {
                                          'indoorCityRate': 2500,
                                          'outdoorCityRate': 10000
                                        },
                                      );

                                      return Container(
                                        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: FareEstimationWidget(
                                          distance: controller.currentPosition.value != null &&
                                                  controller.destinationPosition.value != null
                                              ? FareCalculationService.calculateDistance(
                                                  controller.currentPosition.value!.latitude,
                                                  controller.currentPosition.value!.longitude,
                                                  controller.destinationPosition.value!.latitude,
                                                  controller.destinationPosition.value!.longitude,
                                                )
                                              : 5.0,
                                          serviceType: 'ambulance',
                                          partnerRates: firstPartnerRates,
                                          urgency: 'normal',
                                        ),
                                      );
                                    }
                                    return SizedBox.shrink();
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: EdgeInsets.all(16),
                          padding: EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 20,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Obx(() => _buildEmergencyButton(
                                    icon: Icons.local_hospital,
                                    label: controller.showAmbulances.value
                                        ? 'Ambulances On'
                                        : 'Ambulance',
                                    color: controller.showAmbulances.value
                                        ? Colors.green.shade700
                                        : Colors.green.shade600,
                                    onPressed: controller.navigateToAmbulanceServices,
                                    isActive: controller.showAmbulances.value,
                                  )),
                              Container(
                                width: 1,
                                height: 40,
                                color: Colors.grey.shade200,
                              ),
                              _buildEmergencyButton(
                                icon: Icons.chat_bubble,
                                label: 'SOS Chat',
                                color: primaryBlue,
                                onPressed: controller.navigateToSOSChat,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
"""
path.write_text(text[:start] + new_block + text[end:])
