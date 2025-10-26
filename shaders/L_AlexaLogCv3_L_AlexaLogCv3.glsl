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
//                                                                 Logikô
//

#version 120

uniform sampler2D sceneBuffer; // define input
uniform bool lin_2_log;

void main(void)
{
  vec2 uv = gl_TexCoord[0].xy;
  vec3 color = texture2D(sceneBuffer, uv).rgb;
  vec3 outColor;

  if(lin_2_log)
  {
    outColor = vec3((color.r > 0.010591 ? (0.247190* (log (5.555556*color.r + 0.052272) / 2.30258509299) + 0.385537): (5.367655*color.r) + 0.092809), (color.g > 0.010591 ? (0.247190* (log (5.555556*color.g + 0.052272) / 2.30258509299) + 0.385537): (5.367655*color.g) + 0.092809), (color.b > 0.010591 ? (0.247190* (log (5.555556*color.b + 0.052272) / 2.30258509299) + 0.385537): (5.367655*color.b) + 0.092809));
  }
      else
        outColor = vec3((color.r > 0.1496582 ? (pow(10.0, (color.r - 0.385537) / 0.2471896) - 0.052272) / 5.555556 : (color.r - 0.092809) / 5.367655 ), (color.g > 0.1496582 ? (pow(10.0, (color.g - 0.385537) / 0.2471896) - 0.052272) / 5.555556 : (color.g - 0.092809) / 5.367655 ), (color.b > 0.1496582 ? (pow(10.0, (color.b - 0.385537) / 0.2471896) - 0.052272) / 5.555556 : (color.b - 0.092809) / 5.367655 ));
    gl_FragColor.rgb = outColor;
}
