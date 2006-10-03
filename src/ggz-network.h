/* ggz-network.h */


#define NETWORK_ENGINE "Gnect"
#define NETWORK_VERSION "1"

void network_init (void);
void network_send_move (int column);
void on_network_game (void);
