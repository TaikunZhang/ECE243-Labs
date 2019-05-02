#include <stdio.h>
#include <stdlib.h>
typedef int bool;
#define true 1
#define false 0
volatile int pixel_buffer_start; // global variable

void draw_line( int x0, int y0, int x1, int y1, short int line_colour);
void plot_pixel(int x, int y, short int line_color);
void clear_screen();
int abs(int x);
void vsync();
void draw_square(int x,int y, short int color);

int main(void)
{
    volatile int * pixel_ctrl_ptr = (int *)0xFF203020;
    /* Read location of the pixel buffer from the pixel buffer controller */
    pixel_buffer_start = *pixel_ctrl_ptr;
    *(pixel_ctrl_ptr + 1) = 0xC8000000;

    vsync();
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen();

    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1);
    //initialize stuff
    int dx[8],dy[8],x[8],y[8];
    short int color[8];
    int i;
	
	
    for (i = 0; i < 8; ++i){
        dx[i] = rand() % 2 * 2 - 1;
        dy[i] = rand() % 2 * 2 - 1;
        x[i] = rand() %  250;
        y[i] = rand() % 200;
        color[i] = rand() % 65535;
    }
	 *(pixel_ctrl_ptr + 1) = 0xC8000000; // first store the address in the 
                                        // back buffer
    /* now, swap the front/back buffers, to set the front buffer location */
    wait_for_vsync();
    /* initialize a pointer to the pixel buffer, used by drawing functions */
    pixel_buffer_start = *pixel_ctrl_ptr;
    clear_screen(); // pixel_buffer_start points to the pixel buffer
    /* set back pixel buffer to start of SDRAM memory */
    *(pixel_ctrl_ptr + 1) = 0xC0000000;
    pixel_buffer_start = *(pixel_ctrl_ptr + 1); // we draw on the back buffer

 while(1){

        clear_screen();
        
        int k;
        for (k = 0; k < 8; k++){
			
			if (x[k] >= 300) dx[k] = -dx[k];
            if (x[k] <= 20) dx[k] = -dx[k];
            if (y[k] >= 220) dy[k] = -dy[k];
            if (y[k] <= 20) dy[k] = -dy[k];
			x[k] = x[k] + dx[k];
            y[k] = y[k] + dy[k];
            draw_square(x[k], y[k], color[k]);
		}
		//int j;
		//for (j = 0; j < 7; j++){
		//	draw_line(x[j],y[j],x[j+1],y[j+1],0xF81F);
			
		//}
			draw_line(x[0],y[0],x[1],y[1],0xF81F);
			draw_line(x[1],y[1],x[2],y[2],0xF81F);
			draw_line(x[2],y[2],x[3],y[3],0xF81F);
			draw_line(x[4],y[4],x[5],y[5],0xF81F);
			draw_line(x[5],y[5],x[6],y[6],0xF81F);
			draw_line(x[6],y[6],x[7],y[7],0xF81F);
			draw_line(x[7],y[7],x[0],y[0],0xF81F);
			
				
				
			// int k;
			 
       /* for (k = 0; k < 8; k++){
            draw_square(x[k], y[k],0);
		}
			draw_line(x[0],y[0],x[1],y[1],0);
			draw_line(x[1],y[1],x[2],y[2],0);
			draw_line(x[2],y[2],x[3],y[3],0);
			draw_line(x[4],y[4],x[5],y[5],0);
			draw_line(x[5],y[5],x[6],y[6],0);
			draw_line(x[6],y[6],x[7],y[7],0);
			draw_line(x[7],y[7],x[0],y[0],0);*/
		
        vsync();
        pixel_buffer_start = *(pixel_ctrl_ptr + 1);
    }

}




void draw_square(int x,int y, short int color){
    int i,j;
    for (i = 0; i < 4; ++i){
        for (j = 0; j < 4; ++j){
            plot_pixel(x + i, y + j, color);
        }
    }
}
// code not shown for clear_screen() and draw_line() subroutines
void vsync(){
    volatile int* status_register =  0xFF203020;
    register int status;

    *status_register = 1; // set B to 1
    status = *(status_register + 3);
    while((status & 0x001) != 0)
    {
        status = *(status_register + 3);
    }
}

void plot_pixel(int x, int y, short int line_color)
{
    *(short int *)(pixel_buffer_start + (y << 10) + (x << 1)) = line_color;
}
//iterate through and draw black pixels

void clear_screen (){
    int i,j;

    for (i = 0; i < 320; i++){
        for (j = 0; j < 240; j++){

            plot_pixel(i,j,0);
        }
    }
}
void draw_line(int x0, int y0, int x1, int y1, short int line_color){
  bool is_steep = abs(y1 - y0) > abs(x1 - x0);
  if(is_steep){
      int a = x0;
      x0 = y0;
      y0 = a;

      a = x1;
      x1 = y1;
      y1 = a;
  }
  if(x0 > x1){
      int a = x0;
      x0 = x1;
      x1 = a;

      a = y0;
      y0 = y1;
      y1 = a;
  }
  int deltaX = x1 - x0;
  int deltaY = abs(y1 - y0);
  int error = (-deltaX)/2;
  int x;
  int y = y0;
  int y_step;
  if(y0 < y1){
    y_step = 1;
  } else{
    y_step = -1;
  }

  for(x = x0; x < x1; ++x){
    if(is_steep)
      plot_pixel(y,x , line_color);
    else
      plot_pixel(x,y , line_color);

    error += deltaY;

    if(error >= 0){
      y += y_step;
      error -= deltaX;
    }
  }
}
int abs(int x)
{
    if(x < 0) return (-1 * x);
    else return x;
}