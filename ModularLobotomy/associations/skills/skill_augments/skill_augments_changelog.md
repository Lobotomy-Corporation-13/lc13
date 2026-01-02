# Skill Augments System Changelog

This file tracks all changes made to the Skill Augments system for easy wiki page updates.

## Hotfixes

### Hotfix 1.0.1 - Compilation Fixes
**Date**: 2025-10-12

### Fixed
- **template.get() undefined proc error**: Replaced with proper DM syntax using bracket notation
- **Missing hypospray.ogg sound file**: Replaced with existing 'sound/items/syringeproj.ogg'
- **Unused template variable warning**: Removed unused variable by inlining condition check

### Changed
- Sound effects for injectable augments now use syringeproj.ogg instead of hypospray.ogg

---

## Version 2.0.0 - Material System Overhaul
**Date**: 2025-10-12

### Changed
- **Complete Material System Redesign**
  - Replaced specific material requirements with a unified material density system
  - Fabricator now stores a single "total material" value instead of tracking specific items
  - All tresmetals now have a `mat_density` variable that determines their material contribution
  - Templates now have flat material costs instead of specific item requirements

### Material Density Values
- Each tresmetal item contributes its mat_density value when inserted
- Material costs are now simple numerical values deducted from total stored material
- Base tresmetal: 10 mat_density
- Basic tresmetals (steel, cobalt, bloodiron, darksteel): 20 mat_density
- Level-based tresmetals (copper: 25, goldsteel: 40, silversteel: 60, electrum: 80)
- One-level tresmetals (puremetal, pinksteel): 100 mat_density

### Template Material Costs (Updated)
- Basic: 50 material (was 100)
- Enhanced: 100 material (was 200)
- Advanced: 200 material (was 400)
- Superior: 400 material (was 800)
- Masterwork: 800 material (was 1600)
- Injectable Basic: 25 material (was 50)
- Injectable Enhanced: 50 material (was 100)
- Injectable Advanced: 100 material (was 200)
- Injectable Superior: 200 material (was 400)
- Injectable Masterwork: 400 material (was 800)

### UI Changes
- Simplified material display shows single total material value
- Removed complex material requirements list
- Clearer cost display for templates

### Technical Changes
- Added `mat_density` variable to all tresmetals
- Updated fabricator's `attackby()` and material storage system
- Simplified material checking logic
- Updated TGUI interface to reflect new system

---

## Hotfix 2.0.1 - Cost Reduction
**Date**: 2025-10-12

### Changed
- **Reduced all template material costs by 50%**
  - Makes skill augments more accessible to players
  - Regular templates now cost 50-800 material (down from 100-1600)
  - Injectable templates now cost 25-400 material (down from 50-800)

---

## Version 3.0.0 - Skill Augment Catalogue System
**Date**: 2025-10-12

### Added
- **Skill Augment Catalogue Machine** (`/obj/machinery/skill_augment_catalogue`)
  - Planning interface for designing augments without materials
  - Identical UI to fabricator with Template Selection, Skill Configuration, and Create Order tabs
  - Open access for all players (no role restrictions)
  - Creates personalized order tickets instead of actual augments

- **Skill Augment Ticket System** (`/obj/item/skill_augment_ticket`)
  - Physical tickets that store complete augment design data
  - Includes template info, selected skills, material cost, and orderer name
  - Random colors for visual distinction
  - Unique ticket IDs to prevent duplication
  - Rich examine text showing all order details

- **Ticket Processing Integration**
  - Updated fabricator's `attackby()` to accept tickets from authorized roles
  - Role restriction: "Prosthetics Surgeon", "Office Director", "Office Fixer", "Doctor", "Fixer", "Workshop Attendant"
  - Automatic design setup and fabrication start when ticket is processed
  - Material validation before processing
  - Ticket consumption after successful processing

### UI Features
- **Catalogue Interface**: Complete clone of fabricator UI with "Create Order Ticket" functionality
- **Ticket Examination**: Detailed information display including order ID, orderer name, skills list
- **Error Handling**: Proper feedback for invalid tickets, insufficient materials, unauthorized access

### Workflow
1. **Design Phase**: Players use Catalogue to freely experiment with augment designs
2. **Order Creation**: Complete designs generate personalized tickets with material costs
3. **Processing**: Authorized staff use tickets on Fabricator for automatic fabrication
4. **Validation**: System checks materials and authorization before processing

### Benefits
- **Discoverability**: Players can freely explore all templates and skills without materials
- **Authorization**: Maintains role restrictions for actual fabrication
- **Planning**: Enables advance ordering and coordination between players
- **Transparency**: Clear material costs and requirements displayed on tickets

---

## Hotfix 3.0.1 - Max Charge Increase
**Date**: 2025-10-12

### Changed
- **Increased all template max charge values by 50%**
  - Basic: 90 charge (was 60)
  - Enhanced: 150 charge (was 100)
  - Advanced: 240 charge (was 160)
  - Superior: 375 charge (was 250)
  - Masterwork: 525 charge (was 350)
  - Injectable Basic: 45 charge (was 30)
  - Injectable Enhanced: 75 charge (was 50)
  - Injectable Advanced: 120 charge (was 80)
  - Injectable Superior: 190 charge (was 125) - rounded to multiple of 5
  - Injectable Masterwork: 265 charge (was 175) - rounded to multiple of 5

### Rationale
- Provides more charge capacity for skill usage
- Reduces frequency of BURN damage from overuse
- Makes augments more viable for extended combat
- All values now multiples of 5 for consistency

---

## Hotfix 3.0.2 - UI Improvements
**Date**: 2025-10-12

### Changed
- **Added skill descriptions to both UIs**
  - Skill descriptions now visible directly in the skill table
  - No longer need to hover for tooltips to see descriptions
  - Applies to both Fabricator and Catalogue interfaces
  - Better informed decision-making when selecting skills

### UI Layout
- Added Description column to skill tables
- Adjusted column widths for better readability
- Skill names now bold for better visibility
- Descriptions shown in smaller, muted text

---

## Version 3.1.0 - Public Skill Augment Fabricator
**Date**: 2025-10-12

### Added
- **Public Skill Augment Fabricator** (`/obj/machinery/skill_augment_fabricator/public`)
  - Accessible to all players without role restrictions
  - Cannot be manually operated (no UI access)
  - Only accepts skill augment tickets for processing
  - Charges Ahn instead of materials (material_cost × 30)
  - Solves the issue when no workshop staff are available

### Payment System
- **Ahn-based Payments**: Uses ID card bank account system
- **Cost Formula**: Ticket material cost × 30 Ahn
  - Basic templates: 1,500 Ahn (50 × 30)
  - Enhanced templates: 3,000 Ahn (100 × 30)
  - Advanced templates: 6,000 Ahn (200 × 30)
  - Superior templates: 12,000 Ahn (400 × 30)
  - Masterwork templates: 24,000 Ahn (800 × 30)
  - Injectable variants: Half the cost of regular templates

### Features
- **ID Card Validation**: Requires valid ID with registered bank account
- **Balance Checking**: Validates sufficient funds before processing
- **Payment Processing**: Deducts Ahn and plays cash register sound
- **Error Handling**: Clear feedback for insufficient funds or payment failures
- **Material Rejection**: Refuses tresmetal insertion with helpful message

### Benefits
- **Always Available**: Players can get augments even without workshop staff
- **Economic Sink**: Provides Ahn spending option for wealthy players
- **Backup Option**: Ensures skill augment accessibility at all times

---

## Version 3.2.0 - File Organization Restructure
**Date**: 2025-10-13

### Changed
- **Code Organization Overhaul**
  - Split monolithic `skill_augments.dm` file into organized modular files
  - Created dedicated `/skill_augments/` folder structure
  - Separated functionality into logical components for better maintainability

### New File Structure
- **catalogue.dm**: Skill Augment Catalogue machine and ticket system
- **fabricator.dm**: Original Skill Augment Fabricator machine with TGUI interface
- **implants.dm**: Skill augment organs, templates, and implantation system
- **public.dm**: Public Skill Augment Fabricator with Ahn-based payment system
- **tools.dm**: Support tools (tester, batteries, remover) and injectable items

### Technical Changes
- Updated `.dme` project file with new modular includes
- Maintained all existing functionality and interfaces
- No breaking changes to save data or existing augments
- Improved code readability and development workflow

### Benefits
- **Maintainability**: Easier to locate and modify specific components
- **Collaboration**: Multiple developers can work on different aspects simultaneously
- **Code Review**: Smaller, focused files for better review process
- **Debugging**: Isolated systems for targeted troubleshooting

---

## Version 3.3.0 - Rebranding to Body Modifications
**Date**: 2025-10-13

### Changed
- **Complete System Rebranding**
  - Renamed all "Skill Augments" to "Body Modifications" throughout the system
  - Updated all user-facing text, descriptions, and UI labels
  - Maintained all existing functionality while improving clarity

### UI Updates
- **Fabricator Interface**: Updated all titles and labels to use "Body Modification" terminology
- **Catalogue Interface**: Updated order tickets and UI text to reflect new naming
- **Examine Text**: Updated item descriptions and examine messages

### Technical Changes
- Updated machine names and descriptions in all .dm files
- Updated TGUI interface titles and section headers
- Updated vending machine product names and categories
- Updated ticket system text and order displays

### Rationale
- **Clarity**: Distinguishes from other "Augment" systems in the codebase
- **Consistency**: Provides clear, unambiguous naming for the system
- **User Experience**: More descriptive name helps players understand the system's purpose

---

## Version 3.4.0 - Body Modification Importer Delivery System
**Date**: 2025-10-13

### Changed
- **Body Modification Importer Redesign**
  - Renamed from "Public Fabricator" to "Body Modification Importer" to fit setting lore
  - Added delayed delivery system (4-5 minute processing time)
  - Deliveries now arrive via express supply pod directly to the orderer
  - Machine records the orderer and tracks them for delivery

### New Delivery System
- **Processing Delay**: 4-5 minutes randomly selected per order
- **Pod Delivery**: Body modifications arrive in supply pods at the user's location
- **Tracking System**: Follows users even if they move after ordering
- **Fallback Delivery**: If user disconnects, pod delivers to the importer's location
- **Delivery Receipt**: Each order includes a receipt with order details

### User Experience Improvements
- **Clear Messaging**: Users informed of approximate delivery time upon order
- **Delivery Notification**: Alert when pod is arriving at user location
- **Immersive Theme**: Fits the "import from another district" concept better
- **Processing Feedback**: Visual and audio cues during order processing

### Technical Implementation
- Uses weakref system to track user across delivery delay
- Leverages existing supply pod infrastructure
- Maintains all payment and validation systems
- Non-explosive pod delivery (no damage to surroundings)

---

## Version 3.5.0 - Catalogue Service Expansion
**Date**: 2025-10-13

### Added
- **Body Modification Scanner Service**
  - Available at the Body Modification Catalogue for 40 Ahn
  - Shows average stats and maximum compatible rank
  - Displays current modification details including skills and charge
  - Functions like the Body Modification Tester item

- **Body Modification Removal Service**
  - Available at the Body Modification Catalogue for 100 Ahn
  - Automated removal procedure with 3-second processing time
  - Confirmation prompt to prevent accidental removals
  - Functions like the Body Modification Remover item

### User Experience
- **All-in-One Service Station**: Catalogue now serves as comprehensive body mod service center
- **Accessible Services**: Scanning and removal available to all players without special tools
- **Ahn-Based Payments**: Both services use ID card bank account system
- **Audio/Visual Feedback**: Clear sounds and messages for all service operations

### Technical Implementation
- Shared payment system with Body Modification Importer
- Uses existing organ slot system (ORGAN_SLOT_HEART_AID)
- Proper stat calculation and rank determination
- Safe removal with do_after and interruption handling

### Benefits
- **Convenience**: One-stop shop for all body modification needs
- **Accessibility**: No need to find or purchase special tools
- **Economy Integration**: Additional Ahn sinks for the game economy

---

## Hotfix 3.5.1 - Path and Field Corrections
**Date**: 2025-10-13

### Fixed
- **Object Path Corrections**
  - Fixed incorrect paths in public.dm and catalogue.dm
  - Changed `/obj/item/injectable_body_modification` to `/obj/item/body_modification_injectable`
  - Changed `/obj/item/organ/internal/body_modification` to `/obj/item/organ/cyberimp/chest/body_modification`
  - Updated variable references from `installed_skills` to `attached_skills`

- **Missing Field Definitions**
  - Added missing `total_slot_cost` field to body_modification_ticket
  - Added missing `is_injectable` field to body_modification_ticket
  - Ensured proper field population during ticket creation

- **Stat Calculation Fix**
  - Replaced undefined `get_avg_stats()` proc with proper manual stat calculation
  - Uses same logic as implants.dm for consistent stat requirements
  - Calculates average of FORTITUDE, PRUDENCE, TEMPERANCE, and JUSTICE attributes

### Technical Changes
- Removed non-existent template subtype instantiation
- Updated object configuration to use base types with proper property assignment
- Added proper skill charge cost setup for both injectable and implantable versions

---

## Version 3.6.0 - Multiple Order Queue System
**Date**: 2025-10-13

### Added
- **Concurrent Order Processing**
  - Body Modification Importer now supports up to 5 simultaneous orders
  - Queue system replaces single "busy" state that blocked all users
  - Real-time queue status display shows current orders and capacity

### User Experience Improvements
- **Queue Status Display**: Shows current queue position (e.g., "3/5") when using the machine
- **Order Confirmation**: Enhanced feedback shows delivery time and queue position
- **Capacity Management**: Clear messaging when machine is at maximum capacity
- **No More Waiting**: Multiple players can place orders without blocking each other

### Technical Implementation
- **Queue Management**: `pending_orders` list tracks all active orders
- **Configurable Capacity**: `max_concurrent_orders = 5` (easily adjustable)
- **Proper Cleanup**: Orders are removed from queue when delivery completes
- **Thread Safety**: Each order has independent timer and delivery process

### Benefits
- **Improved Accessibility**: No more single-user bottleneck
- **Better Player Experience**: Reduced waiting times during busy periods
- **Scalable System**: Can handle multiple orders without performance impact

---

## Version 3.7.0 - Catalogue UI Service Integration
**Date**: 2025-10-13

### Added
- **Services Tab in Catalogue UI**
  - New fourth tab "Services" added to the Body Modification Catalogue interface
  - Scanning service button with real-time Ahn cost display
  - Removal service button with confirmation and cost display
  - Clear service descriptions and usage instructions

### UI Improvements
- **Integrated Service Access**: Scan and removal services now accessible directly from the TGUI interface
- **Cost Display**: Shows current Ahn costs for both services (40 Ahn scan, 100 Ahn removal)
- **Status Indicators**: Buttons disabled when machine is busy processing
- **User-Friendly Design**: Clear descriptions and visual separation of services

### User Experience
- **One-Click Access**: No need to use attack_hand to access services
- **Visual Feedback**: Red color coding for destructive removal action
- **Informational Design**: NoticeBox explains payment requirements
- **Consistent Interface**: Maintains same design language as other tabs

### Technical Implementation
- **React Components**: New ServicesTab component with proper state management
- **Backend Integration**: Uses existing scan_user and remove_modification actions
- **Data Binding**: Pulls scan_cost and removal_cost from backend data
- **Responsive Design**: Buttons adapt based on machine busy state

---

## Hotfix 3.6.1 - Queue Management Fix
**Date**: 2025-10-13

### Fixed
- **Queue Tracking Bug**
  - Fixed issue where Body Modification Importer would incorrectly show "at maximum capacity" after processing first order
  - Improved queue management using unique order IDs instead of complex data structure comparison
  - Queue now properly tracks and removes completed orders

### Technical Changes
- **Unique Order Tracking**: Each order now gets a unique ID for reliable queue management
- **Associative List**: Changed `pending_orders` from list to associative array for better tracking
- **Proper Cleanup**: Orders are now correctly removed from queue when delivery completes

### User Experience
- **Accurate Queue Display**: Queue status now correctly shows actual pending orders
- **No False Capacity Limits**: Players can now place multiple orders as intended
- **Reliable Concurrent Processing**: Multiple orders process independently without interference

---

## Hotfix 3.7.1 - Fabricator Access Control Fix
**Date**: 2025-10-13

### Fixed
- **UI Access Security Vulnerability**
  - Fixed issue where unauthorized users could access Body Modification Fabricator UI
  - Added role checking to all UI interaction points (ui_interact, ui_data, ui_act)
  - Fabricator now properly restricts access to authorized roles only

### Security Improvements
- **Comprehensive Access Control**: Role checking now applied to all UI entry points
- **Data Protection**: Unauthorized users receive empty data instead of sensitive information
- **Action Prevention**: UI actions blocked for unauthorized users with clear feedback

### Technical Changes
- **ui_interact()**: Added can_use_machine() check to prevent UI opening
- **ui_data()**: Returns empty list for unauthorized users
- **ui_act()**: Blocks all actions for unauthorized users
- **Consistent Messaging**: Same error message across all access points

### Affected Roles
Only these roles can access the Body Modification Fabricator:
- Workshop Attendant
- Prosthetics Surgeon
- Office Director
- Office Fixer
- Doctor
- Fixer

---

## Hotfix 3.7.2 - Search Functionality Enhancement
**Date**: 2025-10-13

### Added
- **Skill Search Functionality** in both Body Modification interfaces
  - Added search input field to filter skills by name or description
  - Search is case-insensitive and searches both skill names and descriptions
  - Applied to both Fabricator and Catalogue interfaces
  - Shows "No skills match your search" message when no results found
  - Maintains all existing functionality while improving skill discoverability

### UI Improvements
- **Enhanced Skill Tables**: Added search bar above Available Skills section
- **Improved User Experience**: Players can now quickly find specific skills without scrolling
- **Consistent Interface**: Same search functionality across both machines
- **Real-time Filtering**: Search results update immediately as user types

### Technical Implementation
- Added Input component import to both JavaScript interfaces
- Implemented `useLocalState` for search text persistence
- Added skill filtering logic using `toLowerCase()` and `includes()` methods
- Updated skill display to use filtered results instead of full skill list

### Benefits
- **Better Discoverability**: Easy to find specific skills in large skill lists
- **Improved Workflow**: Faster skill selection process
- **User-Friendly Design**: Intuitive search functionality for all players

---

## Hotfix 3.7.3 - Major Charge System Improvements
**Date**: 2025-10-13

### Changed
- **Doubled all template charge capacities**
  - Regular templates now have 180-1050 charge (was 90-525)
  - Injectable templates now have 90-530 charge (was 45-265)
  - Addresses rapid charge consumption during active skill usage
  - Provides more sustainable combat performance

- **Reduced all battery prices by 50%**
  - Body Modification Battery: 100 Ahn (was 200 Ahn)
  - Body Modification Battery MK-II: 200 Ahn (was 400 Ahn)
  - Body Modification Battery MK-III: 300 Ahn (was 600 Ahn)
  - Body Modification Battery MK-IV: 400 Ahn (was 800 Ahn)
  - Makes charge restoration more affordable

### Updated Template Values
- **Basic**: 180 charge (was 90) | Injectable: 90 charge (was 45)
- **Enhanced**: 300 charge (was 150) | Injectable: 150 charge (was 75)
- **Advanced**: 480 charge (was 240) | Injectable: 240 charge (was 120)
- **Superior**: 750 charge (was 375) | Injectable: 380 charge (was 190)
- **Masterwork**: 1050 charge (was 525) | Injectable: 530 charge (was 265)

### Benefits
- **Extended Combat**: Players can use skills more frequently without running out of charge
- **Reduced BURN Damage**: Less risk of overcharge penalties from insufficient charge
- **Better Viability**: Body modifications now more practical for sustained engagements
- **Improved Balance**: Makes charge management less punishing while maintaining strategic resource planning
- **Affordable Recharging**: Batteries are now more accessible for regular use

---

## Version 3.8.0 - Skulk Skill Rework
**Date**: 2025-10-13

### Changed
- **Skulk Skill Complete Rework**
  - Now makes the user completely invisible (invisibility = INVISIBILITY_MAXIMUM) instead of partial transparency
  - User is now pacified for 12 seconds (10 second invisibility duration + 2 seconds)
  - Prevents offensive actions while maintaining stealth capability
  - Better balance between escape/repositioning utility and combat limitations

### Technical Changes
- Added `owner.invisibility = INVISIBILITY_MAXIMUM`
- Added `owner.apply_status_effect(/datum/status_effect/pacify, duration + 2 SECONDS)`
- Updated skill description to reflect new mechanics

### Rationale
- **Improved Stealth**: Complete invisibility provides better escape and repositioning options
- **Combat Balance**: Pacification prevents abuse of invisibility for offensive actions
- **Strategic Trade-off**: Players must choose between stealth and combat capability
- **Extended Vulnerability**: 2-second pacification after invisibility ends creates risk/reward dynamics

---

## Version 3.9.0 - Dismember Skill Rework to Execute
**Date**: 2025-10-13

### Changed
- **Dismember Skill Renamed to Execute**
  - Now functions as an execution ability for low-health targets
  - Only affects targets below 10% of their maximum HP
  - **For Humans/Carbon Mobs**: Dismembers a random arm (if not immune to dismemberment)
  - **For Simple Animals**: Gibs them instantly (unless they have godmode)
  - No cooldown consumed if no valid targets are found

### Technical Changes
- Added HP threshold check: `M.health > M.maxHealth * 0.1`
- Added godmode check for simple animals: `S.status_flags & GODMODE`
- Improved feedback with execution messages
- Only triggers cooldown when successfully executing a target

### Gameplay Impact
- **Finishing Move**: Functions as a proper execution ability rather than crowd control
- **Strategic Timing**: Requires targets to be weakened first
- **Target Selection**: Works on all living entities but only when critically wounded
- **Resource Efficient**: Doesn't waste cooldown on healthy targets

### Balance Rationale
- **More Strategic**: Requires setup and teamwork to weaken enemies first
- **Less Oppressive**: Can't instantly disable healthy opponents
- **Thematically Appropriate**: Functions as a true finishing move
- **Clear Counterplay**: Stay above 10% HP to avoid execution

---

## Version 3.10.0 - Solar Flare Skill Rework
**Date**: 2025-10-13

### Changed
- **Solar Flare Complete Rework to Area Denial**
  - Creates 4 flashing light zones instead of instant blindness
  - Always places one zone under the caster, plus 3 random zones within 3 tiles
  - Each zone shows yellow sparkle effects for 2 seconds before detonating
  - **Humans**: Take 20 WHITE damage and get blinded for 5 seconds
  - **Simple Animals**: Take 80 WHITE damage total (20 + 60 bonus)

### New Mechanics
- **Delayed Explosion**: 2-second warning period with visual indicators
- **Area Denial**: Forces enemies to reposition or take damage
- **Tactical Positioning**: Caster can use their guaranteed zone strategically
- **Counterplay**: Enemies can move away from visible danger zones

### Technical Implementation
- Added new `/obj/effect/flashing_lights` subtype
- Uses yellow sparkle effects (`icon_state = "sparkles"`)
- Implements `adjustWhiteLoss()` for WHITE damage type
- Added explosion effects and flashbang sound on detonation

### Gameplay Impact
- **Strategic Depth**: Requires positioning and timing rather than instant effect
- **Area Control**: Can block chokepoints or force enemy movement
- **Risk vs Reward**: Caster must position themselves carefully since they're always targeted
- **Enhanced Counterplay**: Enemies get clear visual warning and time to react

---

## Version 3.11.0 - Confusion Skill Line-of-Sight Rework
**Date**: 2025-10-13

### Changed
- **Confusion Skill Gaze Mechanic**
  - Now requires line-of-sight - only affects targets that are facing the caster
  - 1-second warning period with green glow effect
  - Visual indicators appear on all nearby tiles before activation
  - **All Targets**: Applies 4 stacks of LC feeble (40% damage reduction)
  - **Humans/Carbon Mobs**: Confusion, dizziness, blurriness, and silence effects
  - **Simple Animals**: 100 WHITE damage instead of confusion effects

### New Mechanics
- **Line-of-Sight Check**: Uses `is_A_facing_B()` to determine if targets are looking at caster
- **Green Glow Warning**: Caster emits green light for 1 second before effect
- **Visual Indicators**: Green shimmer effects on nearby tiles during warning period
- **Counterplay**: Turn away during the warning period to avoid effects

### Technical Implementation
- Added `INVOKE_ASYNC` for non-blocking skill execution
- Implemented `PerformGaze()` proc for delayed effect
- Uses `owner.set_light(3, 5, "#00FF00", TRUE)` for green glow
- Added `/obj/effect/temp_visual/confusion_gaze` for visual indicators

### Gameplay Impact
- **Strategic Positioning**: Must face targets to affect them
- **Enhanced Counterplay**: Clear warning and avoidance mechanic
- **Risk Management**: Caster is vulnerable during 1-second channel
- **Target Discrimination**: Different effects for humans vs simple mobs
- **Damage Reduction**: Affected targets deal 40% less damage due to feeble stacks

---

## Template for Future Updates

When making changes, add entries in this format:

### [Version Number] - [Brief Description]
**Date**: YYYY-MM-DD

### Added
- New features or content

### Changed
- Modified existing features

### Fixed
- Bug fixes and corrections

### Removed
- Deleted features or content

### Technical Notes
- Implementation details for developers
