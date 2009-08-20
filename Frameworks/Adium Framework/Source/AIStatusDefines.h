//General status types
typedef enum {
	AIAvailableStatusType = 0, /* Must be first in the enum */
	AIAwayStatusType,
	AIInvisibleStatusType,
	AIOfflineStatusType
} AIStatusType;
#define STATUS_TYPES_COUNT 4

//Mutability types
typedef enum {
	AIEditableStatusState = 0, /* A user created state which can be modified -- the default, should be 0 */
	AILockedStatusState, /* A state which is built into Adium and can not be modified */
	AITemporaryEditableStatusState, /* A user created state which is not part of the permanent stored state array */
	AISecondaryLockedStatusState /* A state which is managed by Adium and grouped separately from other states of the same type */
} AIStatusMutabilityType;

typedef enum {
	AIAvailableStatusTypeAS = 'Sonl',
	AIAwayStatusTypeAS = 'Sawy',
	AIInvisibleStatusTypeAS = 'Sinv',
	AIOfflineStatusTypeAS = 'Soff'
} AIStatusTypeApplescript;

#define STATUS_UNIQUE_ID					@"Unique ID"
#define	STATUS_TITLE						@"Title"
#define	STATUS_STATUS_TYPE					@"Status Type"
