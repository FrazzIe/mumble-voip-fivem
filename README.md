# mumble-voip

A tokovoip replacement that uses fivems mumble voip

- Radios (one radio channel per player for now)
- Radio mic clicks
- Calls
- Facial animations when talking
- Phone Speaker mode toggle
- Hear nearby calls and radios
- HTML UI

### Exports
Setters
 
| Export              | Description               | Parameter(s) |
|---------------------|---------------------------|--------------|
| SetMumbleProperty   | Set config options        | string, any  |
| SetRadioChannel     | Set radio channel         | int          |
| SetCallChannel      | Set call channel          | int          |
| AddRadioChannelName | Add name to radio channel | int, string  |

Supported TokoVOIP Exports

| Export                | Description              | Parameter(s) |
|-----------------------|--------------------------|--------------|
| SetTokoProperty       | Set config options       | string, any  |
| addPlayerToRadio      | Set radio channel        | int          |
| removePlayerFromRadio | Remove player from radio |              |
| addPlayerToCall       | Set call channel         | int          |
| removePlayerFromCall  | Remove player from call  |              |

### Credits
@Itokoyamato for TokoVOIP 
@Nardah and @crunchFiveM for Testing
