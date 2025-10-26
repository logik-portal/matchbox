//
//
//                                   MMM                                          
//                                 .MMM.                                          
//                                MMM .                                           
//                               MM.            MMMM                              
//                              MM.           MMMM                                
//                            MM.          MMM                                    
//                           MMMMMMMMMMMMMMM                                      
//                        8MMMMN.  M ..  .MMMMMMM .            .D                 
//                      MMMMMM.    M      MM.   MMM ..     .MMMMMM                
//                    MMM   MM.    MM.    M8     MOMMM. MMMMM   MM                
//                  NMM.    MM.    MM     MM     M.  MMMI       MM                
//                 MM,. .M, MMMMMMMMMMMMMMMMMMMMMMMMMMMMM.      MM.               
//                NMMM.  .  MMM    MM.    MM$   M..=MM. 7MMM.   M,                
//                 .MMMM.   MM     MN     ,M.   M. M.     MMMMMMM~                
//                    .MMM..MM.    MM.    MM.  8MMM.         ..O..                
//                      .MMMMM     M.     MM   MMM                                
//                         MMMMM. .M      MMMM7  MM.                              
//                            MMMMMMMMMMMMM.      MMM                             
//                              MM      MMN.       MMM                            
//                              MM        MM .                                    
//                               M7        MM                                     
//                                                                                
//                                                                 Logik™
//

#version 120
uniform sampler2D sceneBuffer; // define input

void main(void)
{
  vec2 uv = gl_TexCoord[0].xy;
  vec3 color = texture2D(sceneBuffer, uv).rgb;

float red = ((pow(10,(((color.r*1023.0-64.0)/876.0)-(64.0/876.0))/0.529136)-1.0)/10.1596);
float green = ((pow(10,(((color.g*1023.0-64.0)/876.0)-(64.0/876.0))/0.529136)-1.0)/10.1596);
float blue = ((pow(10,(((color.b*1023.0-64.0)/876.0)-(64.0/876.0))/0.529136)-1.0)/10.1596);
 
gl_FragColor.rgb = vec3(red, green, blue);
}
